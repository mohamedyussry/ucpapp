<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_Subscriptions {
    public function __construct() {
        // التحقق من الدفع في ووكومرس (مكتمل أو قيد المعالجة للمنتجات الافتراضية) لتفعيل الاشتراك
        add_action( 'woocommerce_order_status_completed', [ $this, 'activate_subscription_on_payment' ], 10, 1 );
        add_action( 'woocommerce_order_status_processing', [ $this, 'activate_subscription_on_payment' ], 10, 1 );
        
        // التنبيهات المجدولة (Cron Job)
        add_action( 'ucp_daily_subscription_check', [ $this, 'process_daily_subscriptions' ] );

        // معالج روابط التجديد الآمنة
        add_action( 'template_redirect', [ $this, 'handle_safe_renewal_redirect' ] );

        // التحكم في طرق الدفع المسموحة للاشتراكات
        add_filter( 'woocommerce_available_payment_gateways', [ $this, 'filter_gateways_for_subscriptions' ], 10, 1 );
    }

    /**
     * تصفية طرق الدفع إذا كانت السلة تحتوي على اشتراك
     */
    public function filter_gateways_for_subscriptions( $gateways ) {
        if ( is_admin() ) return $gateways;

        $has_subscription = false;
        
        // التحقق من وجود اشتراك في السلة
        if ( function_exists('WC') && WC()->cart ) {
            foreach ( WC()->cart->get_cart() as $cart_item ) {
                if ( get_post_meta( $cart_item['product_id'], '_ucp_is_subscription', true ) === 'yes' ) {
                    $has_subscription = true;
                    break;
                }
            }
        }

        // إذا وجدنا اشتراك، نقوم بالتصفية بناءً على الإعدادات
        if ( $has_subscription ) {
            $allowed = get_option('ucp_subscription_allowed_gateways', []);
            if ( ! empty($allowed) && is_array($allowed) ) {
                foreach ( $gateways as $id => $gateway ) {
                    if ( ! in_array( $id, $allowed ) ) {
                        unset( $gateways[$id] );
                    }
                }
            }
        }

        return $gateways;
    }

    /**
     * معالج التجديد الآمن: يفرغ السلة، يضيف المنتج، ويوجه للتشيك أوت
     * هذا يضمن توافق 100% مع تاببي وتمارا
     */
    public function handle_safe_renewal_redirect() {
        if ( isset($_GET['ucp_renew_plan']) && is_numeric($_GET['ucp_renew_plan']) ) {
            $product_id = intval($_GET['ucp_renew_plan']);
            
            if ( function_exists('WC') && WC()->cart ) {
                WC()->cart->empty_cart();
                WC()->cart->add_to_cart($product_id);
                wp_safe_redirect( wc_get_checkout_url() );
                exit;
            }
        }
    }

    /**
     * تفعيل الاشتراك تلقائياً عند اكتمال الطلب
     */
    public function activate_subscription_on_payment( $order_id ) {
        $order = wc_get_order( $order_id );
        if ( ! $order ) return;

        // التحقق من أن الاشتراك لم يتم تفعيله مسبقاً لهذا الطلب لتجنب التكرار
        if ( $order->get_meta( '_ucp_subscription_activated' ) ) return;

        $user_id = $order->get_user_id();

        if ( ! $user_id ) return;

        $activated = false;
        foreach ( $order->get_items() as $item ) {
            $product_id = $item->get_product_id();
            
            // التحقق مما إذا كان هذا المنتج هو باقة اشتراك
            $is_sub = get_post_meta( $product_id, '_ucp_is_subscription', true );
            
            if ( $is_sub === 'yes' ) {
                $duration = (int) get_post_meta( $product_id, '_ucp_sub_duration', true );
                $plan_name = $item->get_name();
                
                $medical_data = [
                    'الاسم'       => $item->get_meta('اسم المريض'),
                    'رقم الهوية'   => $item->get_meta('رقم الهوية'),
                    'الجوال'      => $item->get_meta('الجوال'),
                    'النوع'       => $item->get_meta('النوع'),
                    'الوزن'       => $item->get_meta('الوزن'),
                    'الطول'       => $item->get_meta('الطول'),
                    'تاريخ الميلاد' => $item->get_meta('تاريخ الميلاد'),
                    'المدينة'      => $item->get_meta('المدينة'),
                    'البريد'       => $item->get_meta('البريد'),
                ];
                if ( ! empty($medical_data['الاسم']) ) {
                    update_user_meta( $user_id, 'ucp_medical_profile', $medical_data );
                }

                $this->update_user_subscription( $user_id, $plan_name, $duration, $order_id );
                $activated = true;
            }
        }

        if ( $activated ) {
            $order->update_meta_data( '_ucp_subscription_activated', 'yes' );
            $order->save();
        }
    }

    /**
     * تحديث بيانات اشتراك المستخدم في قاعدة البيانات
     */
    public function update_user_subscription( $user_id, $plan_name, $duration, $order_id = 0 ) {
        $start_date = current_time( 'mysql' );
        $days_to_add = $duration;
        
        // إذا كان لديه اشتراك نشط، نقوم بالتمديد من تاريخ الانتهاء القديم
        $current_expiry = get_user_meta( $user_id, 'ucp_subscription_expiry', true );
        $base_time = ( $current_expiry && $current_expiry > time() ) ? $current_expiry : time();
        
        $new_expiry = strtotime( "+{$days_to_add} days", $base_time );

        update_user_meta( $user_id, 'ucp_subscription_status', 'active' );
        update_user_meta( $user_id, 'ucp_subscription_plan_id', $plan_name );
        update_user_meta( $user_id, 'ucp_subscription_start', $start_date );
        update_user_meta( $user_id, 'ucp_subscription_expiry', $new_expiry );
        update_user_meta( $user_id, 'ucp_subscription_order_id', $order_id );

        // إضافة ملاحظة للمشرف وإرسال ترحيب للمشترك
        error_log( "UCP: Subscription activated for User #{$user_id} via Order #{$order_id}" );
        
        $welcome_msg = get_option('ucp_subscription_msg_welcome', 'مرحباً بك! تم تفعيل اشتراكك بنجاح، نتمنى لك الاستفادة القصوى من خدماتنا.');
        $this->add_user_notification( $user_id, $welcome_msg );
    }

    /**
     * التحقق من حالة اشتراك المستخدم (تستخدم في الـ API)
     */
    public static function get_status( $user_id ) {
        $expiry = get_user_meta( $user_id, 'ucp_subscription_expiry', true );
        $status = get_user_meta( $user_id, 'ucp_subscription_status', true );
        
        $grace_period = (int) get_option('ucp_subscription_grace_period', 0);
        $grace_seconds = $grace_period * 24 * 60 * 60;

        // حالة الإيقاف المؤقت
        if ( $status === 'paused' ) {
            return [
                'is_active' => false,
                'status'    => 'paused',
                'expiry'    => $expiry ? date('Y-m-d', $expiry) : null
            ];
        }

        // حالة الانتهاء (مع مراعاة فترة السماح)
        if ( ! $expiry || ($expiry + $grace_seconds) < time() || $status === 'expired' ) {
            return [
                'is_active' => false,
                'status'    => 'expired',
                'expiry'    => $expiry ? date('Y-m-d', $expiry) : null
            ];
        }

        return [
            'is_active' => true,
            'status'    => $status,
            'expiry'    => date('Y-m-d', $expiry),
            'plan'      => get_user_meta( $user_id, 'ucp_subscription_plan_id', true )
        ];
    }

    /**
     * الوظيفة المجدولة اليومية (Cron Job)
     */
    public function process_daily_subscriptions( $force_resend = false ) {
        $grace_period = (int) get_option('ucp_subscription_grace_period', 0);
        $grace_seconds = $grace_period * 24 * 60 * 60;
        $now = time();

        $active_users = get_users([
            'meta_key' => 'ucp_subscription_status',
            'meta_value' => 'active'
        ]);

        foreach ($active_users as $user) {
            $expiry = get_user_meta($user->ID, 'ucp_subscription_expiry', true);
            
            // 1. إيقاف الاشتراكات التي انتهت وانقضت فترة السماح لها
            if ( $expiry && ($expiry + $grace_seconds) < $now ) {
                update_user_meta($user->ID, 'ucp_subscription_status', 'expired');
                
                $logs = get_user_meta( $user->ID, 'ucp_subscription_logs', true ) ?: [];
                $logs[] = [
                    'date'   => current_time('mysql'),
                    'action' => 'انتهى الاشتراك تلقائياً وتم تحويل الحالة إلى (منتهي)',
                    'by'     => 'System (Cron)'
                ];
                update_user_meta( $user->ID, 'ucp_subscription_logs', $logs );

                $expired_msg = get_option('ucp_subscription_msg_expired', 'لقد انتهى اشتراكك. نرجو منك تجديد الاشتراك لتستمر في الاستمتاع بخدماتنا عبر التطبيق.');
                $this->add_user_notification( $user->ID, $expired_msg );
            }
            // 2. إرسال تنبيه للمشتركين الذين سينتهي اشتراكهم خلال 3 أيام
            elseif ( $expiry && $expiry > $now && ($expiry - $now) <= (3 * 24 * 60 * 60) ) {
                $last_warned = get_user_meta($user->ID, '_ucp_last_expiry_warning', true);
                // منع التكرار إلا في حالة الفحص اليدوي (Force)
                if ( $force_resend || $last_warned != $expiry ) {
                    $warning_msg = get_option('ucp_subscription_msg_warning', 'عزيزي المشترك، اشتراكك الحالي سينتهي قريباً (خلال أقل من 3 أيام). بادر بالتجديد لتجنب انقطاع الخدمة.');
                    
                    // الحصول على المنتج من الطلب أو الباقة
                    $product_id = 0;
                    $plans = get_option('ucp_subscription_plans', []);
                    $plan_name = get_user_meta($user->ID, 'ucp_subscription_plan_id', true);
                    foreach($plans as $p) {
                        if(($p['name_ar'] ?? '') === $plan_name || ($p['name_en'] ?? '') === $plan_name) {
                            $product_id = $p['product_id']; break;
                        }
                    }

                    if ( $product_id ) {
                        $order_url = add_query_arg( 'ucp_renew_plan', $product_id, home_url('/') );
                        $warning_msg .= "\n\n" . 'بادر بالتجديد الآن لتجنب انقطاع الخدمة عبر الرابط التالي: <br><a href="'.$order_url.'">اضغط هنا لتجديد الاشتراك</a>';
                    }

                    $this->add_user_notification( $user->ID, $warning_msg, 'تنبيه: اقتراب انتهاء الاشتراك وفاتورة التجديد' );
                    update_user_meta($user->ID, '_ucp_last_expiry_warning', $expiry);
                }
            }
        }
    }

    /**
     * إرسال وحفظ إشعار للمستخدم وإرسال بريد إلكتروني
     */
    public function add_user_notification($user_id, $message, $subject = 'تنبيه من تطبيق العيادة') {
        $notifications = get_user_meta( $user_id, 'ucp_user_notifications', true ) ?: [];
        $notifications[] = [
            'date' => current_time('mysql'),
            'message' => $message,
            'read' => false
        ];
        update_user_meta( $user_id, 'ucp_user_notifications', $notifications );
        
        // إرسال بريد إلكتروني (نعتمد على البريد المدخل في الملف الطبي أولاً، ثم الرسمي كبديل)
        $user = get_user_by('id', $user_id);
        $medical_profile = get_user_meta($user_id, 'ucp_medical_profile', true) ?: [];
        $email_to = !empty($medical_profile['البريد']) ? $medical_profile['البريد'] : ($user ? $user->user_email : '');
        
        if ( !empty($email_to) && is_email($email_to) ) {
            $headers = ['Content-Type: text/html; charset=UTF-8'];
            $html_message = "<div style='direction:rtl; text-align:right; font-family:tahoma, sans-serif; background:#f9f9f9; padding:20px; border-radius:10px;'>";
            $html_message .= "<h3 style='color:#f97316;'>أهلاً بك،</h3>";
            $html_message .= "<p style='font-size:16px; line-height:1.6; color:#333;'>" . nl2br($message) . "</p>";
            $html_message .= "<hr style='border:none; border-top:1px solid #ddd; margin:20px 0;'>";
            $html_message .= "<p style='font-size:12px; color:#999;'>هذه الرسالة مرسلة آلياً من نظام إدارة الاشتراكات.</p>";
            $html_message .= "</div>";
            wp_mail($email_to, $subject, $html_message, $headers);
        }
        
        // @TODO: استدعاء دالة الـ FCM لاحقاً لإرسال إشعار مباشر (Push) للهاتف
        // if ( class_exists('UCP_FCM') ) { UCP_FCM::send_notification($user_id, 'تنبيه الاشتراك', $message); }
    }

    /**
     * إنشاء فاتورة تجديد ووكومرس للمشترك
     */
    private function generate_renewal_invoice($user_id, $force = false) {
        $user = get_user_by('id', $user_id);
        if ( ! $user ) return false;

        $original_order_id = get_user_meta( $user_id, 'ucp_subscription_order_id', true );
        $plan_name = get_user_meta( $user_id, 'ucp_subscription_plan_id', true );
        
        $product_id = 0;

        // محاولة جلب المنتج من الطلب الأصلي
        if ( $original_order_id ) {
            $original_order = wc_get_order( $original_order_id );
            if ( $original_order ) {
                foreach ( $original_order->get_items() as $item ) {
                    if ( get_post_meta( $item->get_product_id(), '_ucp_is_subscription', true ) === 'yes' ) {
                        $product_id = $item->get_product_id();
                        break;
                    }
                }
            }
        }

        // إذا لم نجد طلب أصلي أو منتج، نبحث في الباقات المسجلة بالاسم
        if ( ! $product_id && $plan_name ) {
            $plans = get_option('ucp_subscription_plans', []);
            foreach ( $plans as $p ) {
                if ( ($p['name_ar'] ?? '') === $plan_name || ($p['name_en'] ?? '') === $plan_name ) {
                    $product_id = intval($p['product_id'] ?? 0);
                    break;
                }
            }
        }
        
        if ( ! $product_id ) return false;

        // منع تكرار إنشاء الفواتير خلال 5 أيام (إلا في حالة الفحص اليدوي Force)
        if ( ! $force ) {
            $existing_renewals = wc_get_orders([
                'customer_id' => $user_id,
                'status'      => ['pending'],
                'date_created'=> '>=' . date('Y-m-d', strtotime('-5 days')),
            ]);
            if ( !empty($existing_renewals) ) return false;
        }

        $order = wc_create_order( array( 'customer_id' => $user_id ) );
        $product = wc_get_product($product_id);
        if ( ! $product ) {
            $order->delete(true);
            return false;
        }

        $order->add_product( $product, 1 );

        $medical_profile = get_user_meta($user_id, 'ucp_medical_profile', true) ?: [];
        $billing_email = !empty($medical_profile['البريد']) ? $medical_profile['البريد'] : $user->user_email;
        $billing_first_name = !empty($medical_profile['الاسم']) ? $medical_profile['الاسم'] : $user->display_name;
        $billing_phone = !empty($medical_profile['الجوال']) ? $medical_profile['الجوال'] : '';
        $billing_city = !empty($medical_profile['المدينة']) ? $medical_profile['المدينة'] : '';

        $order->set_billing_email( $billing_email );
        $order->set_billing_first_name( $billing_first_name );
        $order->set_billing_last_name( '' );
        $order->set_billing_phone( $billing_phone );
        $order->set_billing_city( $billing_city );
        $order->set_billing_country( 'SA' );
        $order->set_billing_address_1( 'N/A' );

        $order->set_customer_id( $user_id );

        $order->calculate_totals();
        $order->update_status('pending', 'فاتورة تجديد الاشتراك التلقائية عبر UCP', true);
        
        // محاولة إرسال إيميل ووكومرس للفاتورة
        if ( isset( WC()->mailer()->emails['WC_Email_Customer_Invoice'] ) ) {
            WC()->mailer()->emails['WC_Email_Customer_Invoice']->trigger( $order->get_id() );
        }

        return $order->get_id();
    }
}
