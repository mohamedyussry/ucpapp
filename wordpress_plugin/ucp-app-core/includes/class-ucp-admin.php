<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_Admin {
    public function __construct() {
        add_action( 'admin_menu', [ $this, 'add_menus' ] );
        add_action( 'admin_init', [ $this, 'register_settings' ] );
        add_action( 'admin_enqueue_scripts', [ $this, 'enqueue_assets' ] );
        add_action( 'admin_print_footer_scripts', [ $this, 'render_js' ] );
        add_action( 'update_option_ucp_subscription_plans', [ $this, 'sync_plans_with_wc' ], 10, 2 );
        add_action( 'admin_init', [ $this, 'handle_manual_subscription' ] );
        add_action( 'admin_init', [ $this, 'handle_delete_subscription' ] );
        add_action( 'wp_ajax_ucp_search_users', [ $this, 'ajax_search_users' ] );
        add_action( 'wp_ajax_ucp_test_notification', [ $this, 'ajax_test_notification' ] );
        add_action( 'phpmailer_init', [ $this, 'configure_smtp' ] );
        add_action( 'wp_ajax_ucp_send_test_email', [ $this, 'ajax_send_test_email' ] );
        add_action( 'wp_ajax_ucp_run_manual_cron', [ $this, 'ajax_run_manual_cron' ] );
    }

    public function handle_delete_subscription() {
        if ( isset($_POST['ucp_delete_sub_nonce']) && wp_verify_nonce($_POST['ucp_delete_sub_nonce'], 'ucp_delete_sub') ) {
            if ( ! current_user_can('manage_options') ) return;

            $user_id = intval($_POST['ucp_delete_user_id']);
            if ( $user_id ) {
                delete_user_meta( $user_id, 'ucp_subscription_status' );
                delete_user_meta( $user_id, 'ucp_subscription_plan_id' );
                delete_user_meta( $user_id, 'ucp_subscription_start' );
                delete_user_meta( $user_id, 'ucp_subscription_expiry' );
                delete_user_meta( $user_id, 'ucp_subscription_order_id' );
                delete_user_meta( $user_id, 'ucp_medical_profile' );
                delete_user_meta( $user_id, 'ucp_paused_remaining_seconds' );
                delete_user_meta( $user_id, 'ucp_admin_notes' );
                delete_user_meta( $user_id, 'ucp_subscription_logs' );
                
                add_settings_error('ucp_messages', 'ucp_sub_deleted', 'تم حذف اشتراك المستخدم وملفه الطبي بنجاح.', 'updated');
            }
        }
    }

    public function handle_manual_subscription() {
        if ( isset($_POST['ucp_manual_sub_nonce']) && wp_verify_nonce($_POST['ucp_manual_sub_nonce'], 'ucp_save_manual_sub') ) {
            if ( ! current_user_can('manage_options') ) return;

            $user_identifier = sanitize_text_field($_POST['ucp_manual_user']);
            $plan_id = sanitize_text_field($_POST['ucp_manual_plan']);
            $status = sanitize_text_field($_POST['ucp_manual_status']);
            $expiry_date = sanitize_text_field($_POST['ucp_manual_expiry']);
            $notes = sanitize_textarea_field($_POST['ucp_manual_notes']);
            $notify_msg = sanitize_textarea_field($_POST['ucp_manual_notify']);

            // Medical Data
            $med_name   = isset($_POST['ucp_manual_name']) ? sanitize_text_field($_POST['ucp_manual_name']) : '';
            $med_id     = isset($_POST['ucp_manual_id']) ? sanitize_text_field($_POST['ucp_manual_id']) : '';
            $med_mobile = isset($_POST['ucp_manual_mobile']) ? sanitize_text_field($_POST['ucp_manual_mobile']) : '';
            $med_gender = isset($_POST['ucp_manual_gender']) ? sanitize_text_field($_POST['ucp_manual_gender']) : '';
            $med_weight = isset($_POST['ucp_manual_weight']) ? sanitize_text_field($_POST['ucp_manual_weight']) : '';
            $med_height = isset($_POST['ucp_manual_height']) ? sanitize_text_field($_POST['ucp_manual_height']) : '';
            $med_dob    = isset($_POST['ucp_manual_dob']) ? sanitize_text_field($_POST['ucp_manual_dob']) : '';
            $med_city   = isset($_POST['ucp_manual_city']) ? sanitize_text_field($_POST['ucp_manual_city']) : '';

            $user = get_user_by('email', $user_identifier);
            if ( ! $user && is_numeric($user_identifier) ) {
                $user = get_user_by('id', (int)$user_identifier);
            }
            if ( ! $user ) {
                $user = get_user_by('login', $user_identifier);
            }

            if ( $user ) {
                $old_status = get_user_meta( $user->ID, 'ucp_subscription_status', true );
                $current_expiry = get_user_meta( $user->ID, 'ucp_subscription_expiry', true );
                $new_expiry = $current_expiry;

                // Set new expiry if provided via Date picker
                if ( ! empty($expiry_date) ) {
                    $new_expiry = strtotime($expiry_date . ' 23:59:59');
                }

                // Handle pause/resume
                if ( $status === 'paused' && $old_status !== 'paused' ) {
                    $remaining = $new_expiry - time();
                    if ($remaining < 0) $remaining = 0;
                    update_user_meta( $user->ID, 'ucp_paused_remaining_seconds', $remaining );
                    $new_expiry = time(); // Effectively stopped
                } elseif ( $status === 'active' && $old_status === 'paused' ) {
                    // Only resume remaining days if the admin didn't explicitly set a new expiry date
                    if ( empty($_POST['ucp_manual_expiry']) ) {
                        $remaining = (int) get_user_meta( $user->ID, 'ucp_paused_remaining_seconds', true );
                        $new_expiry = time() + $remaining;
                    }
                    delete_user_meta( $user->ID, 'ucp_paused_remaining_seconds' );
                }

                // Update Meta
                update_user_meta( $user->ID, 'ucp_subscription_status', $status );
                update_user_meta( $user->ID, 'ucp_subscription_plan_id', $plan_id );
                update_user_meta( $user->ID, 'ucp_admin_notes', $notes );
                
                // Update Medical Profile if provided
                if ( ! empty($med_name) || ! empty($med_mobile) ) {
                    $existing_profile = get_user_meta( $user->ID, 'ucp_medical_profile', true ) ?: [];
                    $medical_profile = array_merge($existing_profile, [
                        'الاسم'       => $med_name,
                        'رقم الهوية'   => $med_id,
                        'الجوال'      => $med_mobile,
                        'النوع'       => $med_gender,
                        'الوزن'       => $med_weight,
                        'الطول'       => $med_height,
                        'تاريخ الميلاد' => $med_dob,
                        'المدينة'      => $med_city,
                    ]);
                    update_user_meta( $user->ID, 'ucp_medical_profile', $medical_profile );
                }

                if ( ! get_user_meta( $user->ID, 'ucp_subscription_start', true ) ) {
                    update_user_meta( $user->ID, 'ucp_subscription_start', current_time('mysql') );
                }
                update_user_meta( $user->ID, 'ucp_subscription_expiry', $new_expiry );

                // Handle Notification
                if ( ! empty($notify_msg) ) {
                    $notifications = get_user_meta( $user->ID, 'ucp_user_notifications', true ) ?: [];
                    $notifications[] = [
                        'date' => current_time('mysql'),
                        'message' => $notify_msg,
                        'read' => false
                    ];
                    update_user_meta( $user->ID, 'ucp_user_notifications', $notifications );
                    // @TODO: Hook to FCM push notification here later
                }

                // Add to Log
                $logs = get_user_meta( $user->ID, 'ucp_subscription_logs', true ) ?: [];
                $log_action = "تحديث يدوي: الحالة ({$status})، الباقة ({$plan_id})";
                if ( ! empty($expiry_date) ) $log_action .= "، الانتهاء ({$expiry_date})";
                if ( ! empty($notify_msg) ) $log_action .= "، (تم إرسال إشعار)";

                $logs[] = [
                    'date'   => current_time('mysql'),
                    'action' => $log_action,
                    'by'     => wp_get_current_user()->display_name
                ];
                update_user_meta( $user->ID, 'ucp_subscription_logs', $logs );

                add_settings_error('ucp_messages', 'ucp_sub_updated', 'تم تحديث اشتراك المستخدم بنجاح.', 'updated');
            } else {
                add_settings_error('ucp_messages', 'ucp_sub_error', 
                    'لم يتم العثور على مستخدم بهذا المعرف: <strong>' . esc_html($user_identifier) . '</strong>. تأكد من صحة البريد الإلكتروني أو رقم ID أو اسم المستخدم (Username).', 
                    'error'
                );
            }
        }
    }

    public function add_menus() {
        add_menu_page(
            'إدارة التطبيق',
            'إدارة التطبيق',
            'manage_options',
            'ucp-app-settings',
            [ $this, 'promotions_page' ],
            'dashicons-smartphone',
            30
        );

        add_submenu_page(
            'ucp-app-settings',
            'الرسائل الترويجية',
            'الرسائل الترويجية',
            'manage_options',
            'ucp-app-settings',
            [ $this, 'promotions_page' ]
        );

        add_submenu_page(
            'ucp-app-settings',
            'عروض السلة',
            'عروض السلة',
            'manage_options',
            'ucp-cart-offers',
            [ $this, 'cart_offers_page' ]
        );

        add_submenu_page(
            'ucp-app-settings',
            'تحديثات التطبيق',
            'تحديثات التطبيق',
            'manage_options',
            'ucp-updates',
            [ $this, 'updates_page' ]
        );

        add_submenu_page(
            'ucp-app-settings',
            'إعدادات FCM',
            'إعدادات FCM',
            'manage_options',
            'ucp-fcm',
            [ $this, 'fcm_page' ]
        );

        add_submenu_page(
            'ucp-app-settings',
            'الاشتراكات',
            'الاشتراكات',
            'manage_options',
            'ucp-subscriptions',
            [ $this, 'subscriptions_page' ]
        );

        add_submenu_page(
            'ucp-app-settings',
            'إعدادات SMTP',
            'بريد SMTP ✉️',
            'manage_options',
            'ucp-smtp',
            [ $this, 'smtp_page' ]
        );
    }

    public function register_settings() {
        // FCM Settings
        register_setting( 'ucp_fcm_group', 'ucp_fcm_service_account_json' );
        register_setting( 'ucp_fcm_group', 'ucp_fcm_status_labels' );

        // Update Settings
        register_setting( 'ucp_update_group', 'ucp_required_version' );
        register_setting( 'ucp_update_group', 'ucp_is_force_update' );
        register_setting( 'ucp_update_group', 'ucp_update_url_android' );
        register_setting( 'ucp_update_group', 'ucp_update_url_ios' );
        register_setting( 'ucp_update_group', 'ucp_update_message_ar' );
        register_setting( 'ucp_update_group', 'ucp_update_message_en' );

        // Cart Offers Settings
        register_setting( 'ucp_cart_offers_group', 'ucp_free_shipping_enabled' );
        register_setting( 'ucp_cart_offers_group', 'ucp_free_shipping_min_amount' );
        register_setting( 'ucp_cart_offers_group', 'ucp_free_shipping_msg_ar' );
        register_setting( 'ucp_cart_offers_group', 'ucp_free_shipping_msg_en' );
        register_setting( 'ucp_cart_offers_group', 'ucp_free_shipping_success_ar' );
        register_setting( 'ucp_cart_offers_group', 'ucp_free_shipping_success_en' );

        // Promotion Settings
        register_setting( 'ucp_promo_group', 'ucp_marquee_enabled' );
        register_setting( 'ucp_promo_group', 'ucp_marquee_text_ar' );
        register_setting( 'ucp_promo_group', 'ucp_marquee_text_en' );
        register_setting( 'ucp_promo_group', 'ucp_marquee_bg_color' );
        register_setting( 'ucp_promo_group', 'ucp_marquee_text_color' );
        register_setting( 'ucp_promo_group', 'ucp_marquee_target_type' );
        register_setting( 'ucp_promo_group', 'ucp_marquee_target_id' );

        register_setting( 'ucp_promo_group', 'ucp_popup_enabled' );
        register_setting( 'ucp_promo_group', 'ucp_popup_image_id' );
        register_setting( 'ucp_promo_group', 'ucp_popup_link' );
        register_setting( 'ucp_promo_group', 'ucp_popup_target_type' );
        register_setting( 'ucp_promo_group', 'ucp_popup_target_id' );

        // Subscription Plans (standalone group - saving this must NOT affect other subscription settings)
        register_setting( 'ucp_subscriptions_group', 'ucp_subscription_plans' );

        // Subscription General Settings (separate group to avoid wiping plans on save)
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_grace_period' );
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_checkout_page' );
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_allow_new' );
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_msg_welcome' );
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_msg_warning' );
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_msg_expired' );
        register_setting( 'ucp_sub_settings_group', 'ucp_subscription_allowed_gateways' );

        // SMTP Settings
        register_setting( 'ucp_smtp_group', 'ucp_smtp_enabled', ['sanitize_callback' => 'intval'] );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_host', ['sanitize_callback' => 'sanitize_text_field'] );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_port', ['sanitize_callback' => 'intval'] );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_username', ['sanitize_callback' => 'sanitize_email'] );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_password' );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_encryption', ['sanitize_callback' => 'sanitize_text_field'] );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_from_email', ['sanitize_callback' => 'sanitize_email'] );
        register_setting( 'ucp_smtp_group', 'ucp_smtp_from_name', ['sanitize_callback' => 'sanitize_text_field'] );
    }

    /**
     * تطبيق إعدادات SMTP على PHPMailer
     */
    public function configure_smtp( $phpmailer ) {
        if ( get_option('ucp_smtp_enabled') != '1' ) return;
        $host       = get_option('ucp_smtp_host');
        $port       = (int) get_option('ucp_smtp_port', 587);
        $username   = get_option('ucp_smtp_username');
        $password   = get_option('ucp_smtp_password');
        $encryption = get_option('ucp_smtp_encryption', 'tls');
        $from_email = get_option('ucp_smtp_from_email');
        $from_name  = get_option('ucp_smtp_from_name', get_bloginfo('name'));
        if ( empty($host) || empty($username) ) return;
        $phpmailer->isSMTP();
        $phpmailer->Host       = $host;
        $phpmailer->SMTPAuth   = true;
        $phpmailer->Port       = $port;
        $phpmailer->Username   = $username;
        $phpmailer->Password   = $password;
        $phpmailer->SMTPSecure = $encryption;
        if ( !empty($from_email) ) {
            $phpmailer->From     = $from_email;
            $phpmailer->FromName = $from_name;
        }
    }

    public function ajax_send_test_email() {
        if ( ! current_user_can('manage_options') ) wp_die();
        $to = sanitize_email($_POST['to'] ?? '');
        if ( ! is_email($to) ) { wp_send_json_error('البريد غير صحيح'); }
        $error_msg = '';
        add_action('wp_mail_failed', function($err) use (&$error_msg) {
            $error_msg = $err->get_error_message();
        });
        $sent = wp_mail(
            $to,
            'اختبار SMTP - ' . get_bloginfo('name'),
            '<div dir="rtl" style="font-family:tahoma;padding:20px;background:#f9f9f9;border-radius:10px;"><h3 style="color:#f97316;">✅ نظام البريد يعمل!</h3><p>هذه رسالة تجريبية من إضافة UCP للتحقق من إعدادات SMTP.</p></div>',
            ['Content-Type: text/html; charset=UTF-8']
        );
        if ( $sent ) {
            wp_send_json_success('✅ تم إرسال البريد التجريبي إلى ' . esc_html($to) . ' بنجاح!');
        } else {
            wp_send_json_error('❌ فشل الإرسال. ' . ( $error_msg ?: 'تحقق من إعدادات SMTP.' ));
        }
    }

    public function smtp_page() {
        $saved = isset($_GET['settings-updated']) ? '<div class="notice notice-success"><p>✅ تم حفظ إعدادات SMTP.</p></div>' : '';
        ?>
        <div class="wrap" dir="rtl">
            <h1>⚙️ إعدادات SMTP للبريد الإلكتروني</h1>
            <?php echo $saved; ?>
            <div style="display:grid; grid-template-columns:1fr 1fr; gap:30px; margin-top:20px; align-items:start;">
                <div style="background:#fff; padding:25px; border-radius:12px; border:1px solid #e5e7eb; box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                    <h2 style="margin-top:0; font-size:16px;">إعدادات الخادم</h2>
                    <form method="post" action="options.php">
                        <?php settings_fields('ucp_smtp_group'); ?>
                        <table class="form-table">
                            <tr><th>تفعيل SMTP</th><td><label><input type="checkbox" name="ucp_smtp_enabled" value="1" <?php checked(get_option('ucp_smtp_enabled'), '1'); ?>> تفعيل إرسال البريد عبر SMTP</label></td></tr>
                            <tr><th>خادم SMTP (Host)</th><td><input type="text" name="ucp_smtp_host" value="<?php echo esc_attr(get_option('ucp_smtp_host')); ?>" class="regular-text" placeholder="smtp.gmail.com"></td></tr>
                            <tr><th>المنفذ (Port)</th><td>
                                <select name="ucp_smtp_port">
                                    <option value="587" <?php selected(get_option('ucp_smtp_port'), '587'); ?>>587 (TLS - مُوصى به)</option>
                                    <option value="465" <?php selected(get_option('ucp_smtp_port'), '465'); ?>>465 (SSL)</option>
                                    <option value="25" <?php selected(get_option('ucp_smtp_port'), '25'); ?>>25 (بدون تشفير)</option>
                                </select></td></tr>
                            <tr><th>نوع التشفير</th><td>
                                <select name="ucp_smtp_encryption">
                                    <option value="tls" <?php selected(get_option('ucp_smtp_encryption'), 'tls'); ?>>TLS</option>
                                    <option value="ssl" <?php selected(get_option('ucp_smtp_encryption'), 'ssl'); ?>>SSL</option>
                                    <option value="" <?php selected(get_option('ucp_smtp_encryption'), ''); ?>>بدون تشفير</option>
                                </select></td></tr>
                            <tr><th>اسم المستخدم / البريد</th><td><input type="email" name="ucp_smtp_username" value="<?php echo esc_attr(get_option('ucp_smtp_username')); ?>" class="regular-text" placeholder="your@email.com"></td></tr>
                            <tr><th>كلمة المرور / App Password</th><td><input type="password" name="ucp_smtp_password" value="<?php echo esc_attr(get_option('ucp_smtp_password')); ?>" class="regular-text"></td></tr>
                            <tr><th>بريد المُرسِل (From)</th><td><input type="email" name="ucp_smtp_from_email" value="<?php echo esc_attr(get_option('ucp_smtp_from_email')); ?>" class="regular-text" placeholder="no-reply@yoursite.com"></td></tr>
                            <tr><th>اسم المُرسِل</th><td><input type="text" name="ucp_smtp_from_name" value="<?php echo esc_attr(get_option('ucp_smtp_from_name', get_bloginfo('name'))); ?>" class="regular-text"></td></tr>
                        </table>
                        <?php submit_button('حفظ الإعدادات'); ?>
                    </form>
                </div>
                <div>
                    <div style="background:#fff; padding:25px; border-radius:12px; border:1px solid #e5e7eb; margin-bottom:20px; box-shadow:0 2px 8px rgba(0,0,0,0.05);">
                        <h2 style="margin-top:0; font-size:16px;">🧪 اختبار الإرسال</h2>
                        <p style="color:#6b7280;">أدخل بريدك وسيتم إرسال رسالة تجريبية فوراً لمعرفة إذا كانت الإعدادات تعمل.</p>
                        <input type="email" id="ucp_smtp_test_to" class="regular-text" placeholder="test@email.com" style="margin-bottom:10px; width:100%;">
                        <button type="button" class="button button-primary" id="ucp_smtp_test_btn">إرسال رسالة تجريبية</button>
                        <div id="ucp_smtp_test_result" style="margin-top:15px; padding:12px; border-radius:8px; display:none; font-size:13px;"></div>
                    </div>
                    <div style="background:#fffbeb; padding:20px; border-radius:12px; border:1px solid #fde68a;">
                        <h3 style="margin-top:0; font-size:14px; color:#92400e;">📋 إعدادات المزودين الشائعين</h3>
                        <table style="width:100%; font-size:12px; border-collapse:collapse;">
                            <tr style="background:#fef3c7;"><th style="padding:6px; text-align:right; border:1px solid #fde68a;">المزود</th><th style="padding:6px; border:1px solid #fde68a;">Host</th><th style="padding:6px; border:1px solid #fde68a;">Port</th></tr>
                            <tr><td style="padding:6px; border:1px solid #fde68a;">Gmail</td><td style="padding:6px; border:1px solid #fde68a;">smtp.gmail.com</td><td style="padding:6px; border:1px solid #fde68a;">587 TLS</td></tr>
                            <tr><td style="padding:6px; border:1px solid #fde68a;">Outlook</td><td style="padding:6px; border:1px solid #fde68a;">smtp-mail.outlook.com</td><td style="padding:6px; border:1px solid #fde68a;">587 TLS</td></tr>
                            <tr><td style="padding:6px; border:1px solid #fde68a;">Yahoo</td><td style="padding:6px; border:1px solid #fde68a;">smtp.mail.yahoo.com</td><td style="padding:6px; border:1px solid #fde68a;">465 SSL</td></tr>
                        </table>
                        <p style="margin:10px 0 0; font-size:11px; color:#78350f;">⚠️ Gmail يتطلب <strong>App Password</strong> من إعدادات الأمان وليس كلمة مرور الحساب العادية.</p>
                    </div>
                </div>
            </div>
        </div>
        <script>
        jQuery(document).ready(function($){
            $('#ucp_smtp_test_btn').on('click', function(){
                var to = $('#ucp_smtp_test_to').val().trim();
                if(!to){ alert('أدخل بريدك الإلكتروني أولاً'); return; }
                var $result = $('#ucp_smtp_test_result'), $btn = $(this);
                $btn.prop('disabled', true).text('جاري الإرسال...');
                $result.hide();
                $.post(ajaxurl, { action: 'ucp_send_test_email', to: to }, function(res){
                    $btn.prop('disabled', false).text('إرسال رسالة تجريبية');
                    $result.show();
                    if(res.success){
                        $result.css({'background':'#ecfdf5','border':'1px solid #6ee7b7','color':'#065f46'}).html(res.data);
                    } else {
                        $result.css({'background':'#fef2f2','border':'1px solid #fca5a5','color':'#991b1b'}).html(res.data);
                    }
                });
            });
        });
        </script>
        <?php
    }

    public function ajax_run_manual_cron() {
        if ( ! current_user_can('manage_options') ) wp_die();
        if ( class_exists('UCP_Subscriptions') ) {
            $subs = new UCP_Subscriptions();
            $subs->process_daily_subscriptions(true); // نمرر true لإعادة الإرسال حتى لو تم الإرسال مسبقاً لهذا اليوم
            wp_send_json_success('تم الانتهاء من فحص جميع الاشتراكات بنجاح.');
        }
        wp_send_json_error('كلاس UCP_Subscriptions غير موجود.');
    }

    public function fcm_page() {

        ?>
        <div class="wrap">
            <h1>إعدادات إشعارات Firebase (FCM v1)</h1>
            <form method="post" action="options.php">
                <?php settings_fields('ucp_fcm_group'); ?>
                <table class="form-table">
                    <tr>
                        <th>Service Account JSON</th>
                        <td><textarea name="ucp_fcm_service_account_json" rows="10" class="large-text"><?php echo esc_textarea(get_option('ucp_fcm_service_account_json')); ?></textarea></td>
                    </tr>
                </table>
                <h2>تخصيص مسميات الحالات</h2>
                <table class="form-table">
                    <?php
                    $wc_statuses = wc_get_order_statuses();
                    $labels = get_option('ucp_fcm_status_labels', []);
                    foreach ($wc_statuses as $key => $label) {
                        $clean_id = str_replace('wc-', '', $key);
                        $val = $labels[$clean_id] ?? $label;
                        echo "<tr><th>$label</th><td><input type='text' name='ucp_fcm_status_labels[$clean_id]' value='".esc_attr($val)."' class='regular-text'></td></tr>";
                    }
                    ?>
                </table>
                <?php submit_button(); ?>
            </form>
        </div>
        <?php
    }

    public function updates_page() {
        ?>
        <div class="wrap">
            <h1>إعدادات تحديث التطبيق</h1>
            <form method="post" action="options.php">
                <?php settings_fields('ucp_update_group'); ?>
                <table class="form-table">
                    <tr><th>رقم الإصدار المطلوب</th><td><input type="text" name="ucp_required_version" value="<?php echo esc_attr(get_option('ucp_required_version', '1.0.0')); ?>"></td></tr>
                    <tr><th>تحديث إجباري؟</th><td><input type="checkbox" name="ucp_is_force_update" value="1" <?php checked(get_option('ucp_is_force_update'), '1'); ?>></td></tr>
                    <tr><th>رابط Google Play</th><td><input type="url" name="ucp_update_url_android" value="<?php echo esc_attr(get_option('ucp_update_url_android')); ?>" class="large-text"></td></tr>
                    <tr><th>رابط App Store</th><td><input type="url" name="ucp_update_url_ios" value="<?php echo esc_attr(get_option('ucp_update_url_ios')); ?>" class="large-text"></td></tr>
                    <tr><th>رسالة التحديث (عربي)</th><td><textarea name="ucp_update_message_ar" rows="3" class="large-text"><?php echo esc_textarea(get_option('ucp_update_message_ar')); ?></textarea></td></tr>
                    <tr><th>رسالة التحديث (EN)</th><td><textarea name="ucp_update_message_en" rows="3" class="large-text"><?php echo esc_textarea(get_option('ucp_update_message_en')); ?></textarea></td></tr>
                </table>
                <?php submit_button(); ?>
            </form>
        </div>
        <?php
    }

    public function cart_offers_page() {
        ?>
        <div class="wrap">
            <h1>إعدادات عروض السلة (في التطبيق)</h1>
            <form method="post" action="options.php">
                <?php settings_fields('ucp_cart_offers_group'); ?>
                <table class="form-table">
                    <tr>
                        <th>تفعيل عرض الشحن المجاني؟</th>
                        <td><input type="checkbox" name="ucp_free_shipping_enabled" value="1" <?php checked(get_option('ucp_free_shipping_enabled'), '1'); ?>></td>
                    </tr>
                    <tr>
                        <th>الحد الأدنى للشحن المجاني (ر.س)</th>
                        <td><input type="number" name="ucp_free_shipping_min_amount" value="<?php echo esc_attr(get_option('ucp_free_shipping_min_amount', '250')); ?>" class="regular-text"></td>
                    </tr>
                    <tr>
                        <th>الرسالة التحفيزية (عربي)<br><small>استخدم [amount] للمبلغ المتبقي</small></th>
                        <td><textarea name="ucp_free_shipping_msg_ar" rows="3" class="large-text"><?php echo esc_textarea(get_option('ucp_free_shipping_msg_ar', 'أضف منتجات بقيمة [amount] ر.س إضافية للحصول على شحن مجاني!')); ?></textarea></td>
                    </tr>
                    <tr>
                        <th>الرسالة التحفيزية (EN)<br><small>Use [amount] for remaining</small></th>
                        <td><textarea name="ucp_free_shipping_msg_en" rows="3" class="large-text"><?php echo esc_textarea(get_option('ucp_free_shipping_msg_en', 'Add [amount] SAR more to get free shipping!')); ?></textarea></td>
                    </tr>
                    <tr>
                        <th>رسالة النجاح (عربي)</th>
                        <td><textarea name="ucp_free_shipping_success_ar" rows="2" class="large-text"><?php echo esc_textarea(get_option('ucp_free_shipping_success_ar', 'مبروك! لقد تأهلت للحصول على شحن مجاني! 🚀')); ?></textarea></td>
                    </tr>
                    <tr>
                        <th>رسالة النجاح (EN)</th>
                        <td><textarea name="ucp_free_shipping_success_en" rows="2" class="large-text"><?php echo esc_textarea(get_option('ucp_free_shipping_success_en', 'Congratulations! You qualified for free shipping! 🚀')); ?></textarea></td>
                    </tr>
                </table>
                <?php submit_button(); ?>
            </form>
        </div>
        <?php
    }

    public function promotions_page() {
        ?>
        <div class="wrap">
            <h1>إعدادات الرسائل الترويجية (شريط الإعلانات والمنبثقات)</h1>
            <form method="post" action="options.php">
                <?php settings_fields('ucp_promo_group'); ?>
                
                <h2>شريط الإعلانات المتحرك (Marquee)</h2>
                <table class="form-table">
                    <tr><th>تفعيل شريط الإعلانات؟</th><td><input type="checkbox" name="ucp_marquee_enabled" value="1" <?php checked(get_option('ucp_marquee_enabled'), '1'); ?>></td></tr>
                    <tr><th>النص (عربي)</th><td><input type="text" name="ucp_marquee_text_ar" value="<?php echo esc_attr(get_option('ucp_marquee_text_ar')); ?>" class="large-text"></td></tr>
                    <tr><th>النص (EN)</th><td><input type="text" name="ucp_marquee_text_en" value="<?php echo esc_attr(get_option('ucp_marquee_text_en')); ?>" class="large-text"></td></tr>
                    <tr><th>لون الخلفية</th><td><input type="color" name="ucp_marquee_bg_color" value="<?php echo esc_attr(get_option('ucp_marquee_bg_color', '#ff9800')); ?>"></td></tr>
                    <tr><th>لون النص</th><td><input type="color" name="ucp_marquee_text_color" value="<?php echo esc_attr(get_option('ucp_marquee_text_color', '#ffffff')); ?>"></td></tr>
                    <tr>
                        <th>نوع الوجهة للإعلان المتحرك</th>
                        <td>
                            <select name="ucp_marquee_target_type">
                                <option value="product" <?php selected(get_option('ucp_marquee_target_type'), 'product'); ?>>منتج (Product)</option>
                                <option value="category" <?php selected(get_option('ucp_marquee_target_type'), 'category'); ?>>فئة (Category)</option>
                                <option value="brand" <?php selected(get_option('ucp_marquee_target_type'), 'brand'); ?>>ماركة (Brand)</option>
                                <option value="external" <?php selected(get_option('ucp_marquee_target_type'), 'external'); ?>>رابط خارجي (External Link)</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <th>معرف الوجهة للإعلان المتحرك</th>
                        <td>
                            <input type="text" name="ucp_marquee_target_id" value="<?php echo esc_attr(get_option('ucp_marquee_target_id')); ?>" class="large-text" placeholder="ID or URL">
                        </td>
                    </tr>
                </table>

                <hr>

                <h2>إعلان منبثق (Popup Banner)</h2>
                <table class="form-table">
                    <tr><th>تفعيل المنبثق؟</th><td><input type="checkbox" name="ucp_popup_enabled" value="1" <?php checked(get_option('ucp_popup_enabled'), '1'); ?>></td></tr>
                    <tr>
                        <th>صورة الإعلان</th>
                        <td>
                            <?php 
                            $img_id = get_option('ucp_popup_image_id');
                            $img_url = $img_id ? wp_get_attachment_url($img_id) : '';
                            ?>
                            <div class="preview" style="margin-bottom:10px;">
                                <?php if($img_url): ?><img src="<?php echo $img_url; ?>" style="max-width:200px;"><?php endif; ?>
                            </div>
                            <input type="hidden" name="ucp_popup_image_id" value="<?php echo esc_attr($img_id); ?>">
                            <button type="button" class="button ucp_upload_button">اختر صورة</button>
                        </td>
                    </tr>
                    <tr>
                        <th>نوع الوجهة (Target Type)</th>
                        <td>
                            <select name="ucp_popup_target_type">
                                <option value="product" <?php selected(get_option('ucp_popup_target_type'), 'product'); ?>>منتج (Product)</option>
                                <option value="category" <?php selected(get_option('ucp_popup_target_type'), 'category'); ?>>فئة (Category)</option>
                                <option value="brand" <?php selected(get_option('ucp_popup_target_type'), 'brand'); ?>>ماركة (Brand)</option>
                                <option value="external" <?php selected(get_option('ucp_popup_target_type'), 'external'); ?>>رابط خارجي (External Link)</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <th>معرف الوجهة (Target ID / URL)</th>
                        <td>
                            <input type="text" name="ucp_popup_target_id" value="<?php echo esc_attr(get_option('ucp_popup_target_id')); ?>" class="large-text" placeholder="ID specified for product/cat/brand, or URL for external">
                        </td>
                    </tr>
                </table>

                <?php submit_button(); ?>
            </form>
        </div>
        <?php
    }

    public function subscriptions_page() {
        $active_tab = isset($_GET['tab']) ? $_GET['tab'] : 'plans';
        ?>
        <div class="wrap ucp-admin-wrap">
            <h1>إدارة الاشتراكات والمشتركين</h1>
            
            <h2 class="nav-tab-wrapper">
                <a href="?page=ucp-subscriptions&tab=plans" class="nav-tab <?php echo $active_tab == 'plans' ? 'nav-tab-active' : ''; ?>">باقات الاشتراك</a>
                <a href="?page=ucp-subscriptions&tab=subscribers" class="nav-tab <?php echo $active_tab == 'subscribers' ? 'nav-tab-active' : ''; ?>">المشتركون</a>
                <a href="?page=ucp-subscriptions&tab=settings" class="nav-tab <?php echo $active_tab == 'settings' ? 'nav-tab-active' : ''; ?>">الإعدادات</a>
            </h2>

            <div class="tab-content" style="margin-top: 20px;">
                <?php if ($active_tab == 'plans'): ?>
                    <?php $this->render_plans_tab(); ?>
                <?php elseif ($active_tab == 'settings'): ?>
                    <?php $this->render_subscription_settings_tab(); ?>
                <?php else: ?>
                    <?php $this->render_subscribers_tab(); ?>
                <?php endif; ?>
            </div>
        </div>
        <style>
            .ucp-plan-card { background: #fff; border: 1px solid #ccd0d4; padding: 15px; margin-bottom: 15px; border-radius: 8px; position: relative; border-left: 5px solid #2271b1; }
            .ucp-plan-card h3 { margin-top: 0; }
            .ucp-plan-card .actions { position: absolute; top: 15px; left: 15px; }
            .ucp-feature-item { display: flex; align-items: center; margin-bottom: 5px; }
            .ucp-feature-item input { flex: 1; margin-right: 5px; }
            .ucp-color-dot { display: inline-block; width: 12px; height: 12px; border-radius: 50%; margin-right: 5px; }
        </style>
        <?php
    }

    private function render_plans_tab() {
        $plans = get_option('ucp_subscription_plans', []);
        if (!is_array($plans)) $plans = json_decode($plans, true) ?: [];
        ?>
        <form method="post" action="options.php">
            <?php settings_fields('ucp_subscriptions_group'); ?>
            <div id="ucp-plans-container">
                <?php foreach ($plans as $index => $plan): ?>
                    <div class="ucp-plan-card" data-index="<?php echo $index; ?>">
                        <input type="hidden" name="ucp_subscription_plans[<?php echo $index; ?>][product_id]" value="<?php echo esc_attr($plan['product_id'] ?? 0); ?>">
                        <div class="actions">
                            <button type="button" class="button button-link-delete ucp-remove-plan">حذف الباقة</button>
                        </div>
                        <table class="form-table">
                            <tr>
                                <th>اسم الباقة (عربي / EN)</th>
                                <td>
                                    <input type="text" name="ucp_subscription_plans[<?php echo $index; ?>][name_ar]" value="<?php echo esc_attr($plan['name_ar']); ?>" placeholder="الباقة الذهبية">
                                    <input type="text" name="ucp_subscription_plans[<?php echo $index; ?>][name_en]" value="<?php echo esc_attr($plan['name_en']); ?>" placeholder="Gold Plan">
                                </td>
                            </tr>
                            <tr>
                                <th>السعر والمدة (أيام)</th>
                                <td>
                                    السعر: <input type="number" name="ucp_subscription_plans[<?php echo $index; ?>][price]" value="<?php echo esc_attr($plan['price']); ?>" style="width:80px;">
                                    المدة: <input type="number" name="ucp_subscription_plans[<?php echo $index; ?>][duration]" value="<?php echo esc_attr($plan['duration']); ?>" style="width:80px;"> أيام
                                </td>
                            </tr>
                            <tr>
                                <th>اللون والمظهر</th>
                                <td>
                                    <input type="color" name="ucp_subscription_plans[<?php echo $index; ?>][color]" value="<?php echo esc_attr($plan['color'] ?? '#2271b1'); ?>">
                                    <label><input type="checkbox" name="ucp_subscription_plans[<?php echo $index; ?>][is_popular]" value="1" <?php checked($plan['is_popular'] ?? 0, 1); ?>> باقة مميزة (Popular)</label>
                                </td>
                            </tr>
                            <tr>
                                <th>المميزات</th>
                                <td class="features-list">
                                    <?php 
                                    $features = $plan['features'] ?? [];
                                    foreach ($features as $f_idx => $feature): ?>
                                        <div class="ucp-feature-item">
                                            <input type="text" name="ucp_subscription_plans[<?php echo $index; ?>][features][]" value="<?php echo esc_attr($feature); ?>">
                                            <button type="button" class="button ucp-remove-feature">×</button>
                                        </div>
                                    <?php endforeach; ?>
                                    <button type="button" class="button ucp-add-feature" data-plan="<?php echo $index; ?>">+ إضافة ميزة</button>
                                </td>
                            </tr>
                        </table>
                    </div>
                <?php endforeach; ?>
            </div>
            <p>
                <button type="button" class="button button-primary" id="ucp-add-new-plan">إضافة باقة اشتراك جديدة</button>
            </p>
            <?php submit_button('حفظ التغييرات'); ?>
        </form>

        <script>
        jQuery(document).ready(function($){
            $('#ucp-add-new-plan').click(function(){
                var index = $('#ucp-plans-container .ucp-plan-card').length;
                var html = `
                    <div class="ucp-plan-card" data-index="${index}">
                        <div class="actions"><button type="button" class="button button-link-delete ucp-remove-plan">حذف الباقة</button></div>
                        <table class="form-table">
                            <tr><th>اسم الباقة (عربي / EN)</th><td><input type="text" name="ucp_subscription_plans[${index}][name_ar]" placeholder="اسم الباقة"><input type="text" name="ucp_subscription_plans[${index}][name_en]" placeholder="Plan Name"></td></tr>
                            <tr><th>السعر والمدة (أيام)</th><td>السعر: <input type="number" name="ucp_subscription_plans[${index}][price]" style="width:80px;"> المدة: <input type="number" name="ucp_subscription_plans[${index}][duration]" style="width:80px;"> أيام</td></tr>
                            <tr><th>اللون والمظهر</th><td><input type="color" name="ucp_subscription_plans[${index}][color]" value="#2271b1"> <label><input type="checkbox" name="ucp_subscription_plans[${index}][is_popular]" value="1"> باقة مميزة</label></td></tr>
                            <tr><th>المميزات</th><td class="features-list"><button type="button" class="button ucp-add-feature" data-plan="${index}">+ إضافة ميزة</button></td></tr>
                        </table>
                    </div>`;
                $('#ucp-plans-container').append(html);
            });

            $(document).on('click', '.ucp-add-feature', function(){
                var planIdx = $(this).data('plan');
                var html = `<div class="ucp-feature-item"><input type="text" name="ucp_subscription_plans[${planIdx}][features][]" placeholder="ميزة جديدة"><button type="button" class="button ucp-remove-feature">×</button></div>`;
                $(this).before(html);
            });

            $(document).on('click', '.ucp-remove-feature', function(){ $(this).closest('.ucp-feature-item').remove(); });
            $(document).on('click', '.ucp-remove-plan', function(){ if(confirm('هل أنت متأكد من حذف هذه الباقة؟')) $(this).closest('.ucp-plan-card').remove(); });
        });
        </script>
        <?php
    }

    private function render_subscription_settings_tab() {
        ?>
        <form method="post" action="options.php">
            <?php settings_fields('ucp_sub_settings_group'); ?>
            <table class="form-table">
                <tr>
                    <th>رابط صفحة الدفع المخصصة</th>
                    <td>
                        <input type="url" name="ucp_subscription_checkout_page" value="<?php echo esc_url(get_option('ucp_subscription_checkout_page')); ?>" class="large-text" placeholder="https://your-site.com/checkout/">
                        <p class="description">الرابط الذي سيتم توجيه المستخدم إليه عند الضغط على "اشترك" في التطبيق.</p>
                    </td>
                </tr>
                <tr>
                    <th>فترة السماح (أيام)</th>
                    <td>
                        <input type="number" name="ucp_subscription_grace_period" value="<?php echo esc_attr(get_option('ucp_subscription_grace_period', '0')); ?>" style="width:80px;"> أيام
                        <p class="description">عدد الأيام التي يبقى فيها الاشتراك فعالاً بعد تاريخ الانتهاء الرسمي.</p>
                    </td>
                </tr>
                <tr>
                    <th>السماح باشتراكات جديدة؟</th>
                    <td>
                        <label><input type="checkbox" name="ucp_subscription_allow_new" value="1" <?php checked(get_option('ucp_subscription_allow_new', '1'), '1'); ?>> نعم، استقبل مشتركين جدد.</label>
                        <p class="description">عند التعطيل، لن يتمكن زوار التطبيق من الاشتراك في الباقات.</p>
                    </td>
                </tr>
                <tr>
                    <th>رسالة الترحيب (تفعيل الاشتراك)</th>
                    <td>
                        <textarea name="ucp_subscription_msg_welcome" class="large-text" rows="3"><?php echo esc_textarea(get_option('ucp_subscription_msg_welcome', 'مرحباً بك! تم تفعيل اشتراكك بنجاح، نتمنى لك الاستفادة القصوى من خدماتنا.')); ?></textarea>
                    </td>
                </tr>
                <tr>
                    <th>تنبيه قرب الانتهاء (أقل من 3 أيام)</th>
                    <td>
                        <textarea name="ucp_subscription_msg_warning" class="large-text" rows="3"><?php echo esc_textarea(get_option('ucp_subscription_msg_warning', 'عزيزي المشترك، اشتراكك الحالي سينتهي قريباً (خلال أقل من 3 أيام). بادر بالتجديد لتجنب انقطاع الخدمة.')); ?></textarea>
                    </td>
                </tr>
                <tr>
                    <th>تنبيه انتهاء الاشتراك</th>
                    <td>
                        <textarea name="ucp_subscription_msg_expired" class="large-text" rows="3"><?php echo esc_textarea(get_option('ucp_subscription_msg_expired', 'لقد انتهى اشتراكك. نرجو منك تجديد الاشتراك لتستمر في الاستمتاع بخدماتنا عبر التطبيق.')); ?></textarea>
                    </td>
                </tr>
                <tr>
                    <th>طرق الدفع المسموحة للاشتراكات</th>
                    <td>
                        <?php 
                        $gateways = WC()->payment_gateways->payment_gateways();
                        $allowed = get_option('ucp_subscription_allowed_gateways', []);
                        if ( ! is_array($allowed) ) $allowed = [];
                        
                        foreach ( $gateways as $id => $gateway ) : 
                            if ( $gateway->enabled == 'yes' ) :
                            ?>
                            <label style="display:block; margin-bottom:5px;">
                                <input type="checkbox" name="ucp_subscription_allowed_gateways[]" value="<?php echo esc_attr($id); ?>" <?php checked(in_array($id, $allowed)); ?>>
                                <?php echo esc_html($gateway->get_title()); ?> (<?php echo esc_html($id); ?>)
                            </label>
                            <?php 
                            endif;
                        endforeach; 
                        ?>
                        <p class="description">اختر طرق الدفع التي تريد إظهارها عند شراء أو تجديد الاشتراك فقط. إذا لم يتم اختيار أي شيء، ستظهر كافة الطرق.</p>
                    </td>
                </tr>
            </table>
            <?php submit_button(); ?>
        </form>
        <?php
    }

    private function render_subscribers_tab() {
        global $wpdb;
        
        // Stats Summary
        $total_active = count(get_users(['meta_key' => 'ucp_subscription_status', 'meta_value' => 'active']));
        $total_expired = count(get_users(['meta_key' => 'ucp_subscription_status', 'meta_value' => 'expired']));
        $total_paused = count(get_users(['meta_key' => 'ucp_subscription_status', 'meta_value' => 'paused']));
        
        ?>
        <div class="ucp-stats-row" style="display: flex; gap: 20px; margin-bottom: 30px;">
            <div class="ucp-stat-card" style="background: #fff; padding: 20px; border-radius: 10px; flex: 1; border: 1px solid #e5e5e5; text-align: center;">
                <span style="display: block; font-size: 24px; font-weight: bold; color: #46b450;"><?php echo $total_active; ?></span>
                <span style="color: #666;">مشترك نشط</span>
            </div>
            <div class="ucp-stat-card" style="background: #fff; padding: 20px; border-radius: 10px; flex: 1; border: 1px solid #e5e5e5; text-align: center;">
                <span style="display: block; font-size: 24px; font-weight: bold; color: #f56e28;"><?php echo $total_paused; ?></span>
                <span style="color: #666;">موقوف مؤقتاً</span>
            </div>
            <div class="ucp-stat-card" style="background: #fff; padding: 20px; border-radius: 10px; flex: 1; border: 1px solid #e5e5e5; text-align: center;">
                <span style="display: block; font-size: 24px; font-weight: bold; color: #dc3232;"><?php echo $total_expired; ?></span>
                <span style="color: #666;">اشتراك منتهي</span>
            </div>
        </div>

        <div style="margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center;">
            <h2>قائمة المشتركين</h2>
            <div style="display:flex; gap:10px;">
                <button type="button" class="button" id="ucp-run-manual-cron" style="background:#f97316; color:white; border:none;"><span class="dashicons dashicons-update" style="margin-top:4px;"></span> فحص يدوي للاشتراكات</button>
                <button type="button" class="button button-primary" id="ucp-open-manual-sub" onclick="document.getElementById('ucp-manual-sub-modal').style.display='block'; document.getElementById('ucp_manual_user').value='';">إضافة/تعديل مشترك يدوياً</button>
            </div>
        </div>
        
        <?php settings_errors('ucp_messages'); ?>

        <table class="wp-list-table widefat fixed striped">
            <thead>
                <tr>
                    <th>المستخدم</th>
                    <th>الباقة</th>
                    <th>تاريخ البدء</th>
                    <th>تاريخ الانتهاء</th>
                    <th>الحالة</th>
                    <th>إجراءات</th>
                </tr>
            </thead>
            <tbody>
                <?php 
                $subscribers = get_users([
                    'meta_query' => [
                        ['key' => 'ucp_subscription_status', 'compare' => 'EXISTS']
                    ],
                    'number' => 50
                ]);
                
                if ($subscribers): ?>
                    <?php foreach ($subscribers as $user): 
                        $plan_id = get_user_meta($user->ID, 'ucp_subscription_plan_id', true);
                        $expiry = get_user_meta($user->ID, 'ucp_subscription_expiry', true);
                        $status = get_user_meta($user->ID, 'ucp_subscription_status', true);
                        $notes = get_user_meta($user->ID, 'ucp_admin_notes', true);
                        $medical_profile = get_user_meta($user->ID, 'ucp_medical_profile', true) ?: [];
                        
                        // Fallback: If medical profile is missing, fetch directly from the original WooCommerce Order
                        if ( empty($medical_profile) ) {
                            $order_id = get_user_meta($user->ID, 'ucp_subscription_order_id', true);
                            if ( $order_id ) {
                                $order = wc_get_order($order_id);
                                if ( $order ) {
                                    foreach ( $order->get_items() as $item ) {
                                        if ( get_post_meta( $item->get_product_id(), '_ucp_is_subscription', true ) === 'yes' ) {
                                            $fetched_name = $item->get_meta('اسم المريض');
                                            if ( ! empty($fetched_name) ) {
                                                $medical_profile = [
                                                    'الاسم'       => $fetched_name,
                                                    'رقم الهوية'   => $item->get_meta('رقم الهوية'),
                                                    'الجوال'      => $item->get_meta('الجوال'),
                                                    'النوع'       => $item->get_meta('النوع'),
                                                    'الوزن'       => $item->get_meta('الوزن'),
                                                    'الطول'       => $item->get_meta('الطول'),
                                                    'تاريخ الميلاد' => $item->get_meta('تاريخ الميلاد'),
                                                    'المدينة'      => $item->get_meta('المدينة'),
                                                ];
                                                // Save it permanently so it doesn't need to fetch next time
                                                update_user_meta( $user->ID, 'ucp_medical_profile', $medical_profile );
                                            }
                                            break;
                                        }
                                    }
                                }
                            }
                        }

                        $logs = get_user_meta($user->ID, 'ucp_subscription_logs', true) ?: [];
                        
                        // If paused, calculate future expiry for UI purposes
                        $ui_expiry = $expiry;
                        if ( $status == 'paused' ) {
                            $remaining = (int) get_user_meta($user->ID, 'ucp_paused_remaining_seconds', true);
                            $ui_expiry = time() + $remaining;
                        }
                        
                        $status_text = $status == 'active' ? 'نشط ✅' : ($status == 'paused' ? 'موقوف ⏸️' : 'منتهي ❌');
                        $status_color = $status == 'active' ? '#46b450' : ($status == 'paused' ? '#f56e28' : '#dc3232');
                        ?>
                        <tr>
                            <td><strong><?php echo esc_html($user->display_name); ?></strong><br><small><?php echo esc_html($user->user_email); ?></small></td>
                            <td><?php echo esc_html($plan_id ?: '-'); ?></td>
                            <td><?php echo esc_html(get_user_meta($user->ID, 'ucp_subscription_start', true) ?: '-'); ?></td>
                            <td><?php echo $expiry ? date('Y-m-d', $expiry) : '-'; ?></td>
                            <td><span style="color: white; padding: 3px 8px; border-radius: 4px; background: <?php echo $status_color; ?>"><?php echo $status_text; ?></span></td>
                            <td>
                                <button type="button" class="button ucp-edit-user-sub" data-email="<?php echo esc_attr($user->user_email); ?>" data-plan="<?php echo esc_attr($plan_id); ?>" data-status="<?php echo esc_attr($status); ?>" data-expiry="<?php echo $ui_expiry ? date('Y-m-d', $ui_expiry) : ''; ?>" data-notes="<?php echo esc_attr($notes); ?>" title="تعديل"><span class="dashicons dashicons-edit"></span></button>
                                <button type="button" class="button ucp-view-medical" data-profile="<?php echo esc_attr(json_encode($medical_profile)); ?>" title="الملف الطبي"><span class="dashicons dashicons-clipboard"></span></button>
                                <button type="button" class="button ucp-view-logs" data-logs="<?php echo esc_attr(json_encode($logs)); ?>" title="سجل المشترك"><span class="dashicons dashicons-list-view"></span></button>
                                <button type="button" class="button ucp-test-notif"
                                    data-userid="<?php echo esc_attr($user->ID); ?>"
                                    data-nonce="<?php echo wp_create_nonce('ucp_test_notif'); ?>"
                                    title="إرسال بريد تجريبي" style="color:#2271b1;">
                                    <span class="dashicons dashicons-email-alt"></span>
                                </button>
                                <form method="post" style="display:inline;" onsubmit="return confirm('هل أنت متأكد من حذف اشتراك هذا العميل ومسح ملفه الطبي بالكامل؟ لا يمكن التراجع عن هذا الإجراء.');">
                                    <?php wp_nonce_field('ucp_delete_sub', 'ucp_delete_sub_nonce'); ?>
                                    <input type="hidden" name="ucp_delete_user_id" value="<?php echo esc_attr($user->ID); ?>">
                                    <button type="submit" class="button" title="حذف الاشتراك" style="color: #dc3232;"><span class="dashicons dashicons-trash"></span></button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php else: ?>
                    <tr><td colspan="6">لا يوجد مشتركون حالياً.</td></tr>
                <?php endif; ?>
            </tbody>
        </table>

        <!-- Manual Sub Modal (Hidden) -->
        <div id="ucp-manual-sub-modal" style="display:none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 9999;">
            <div style="background: #fff; width: 500px; max-height: 90vh; overflow-y: auto; margin: 5vh auto; padding: 20px; border-radius: 10px;">
                <h3>إضافة/تعديل اشتراك يدوياً</h3>
                <form method="post" action="">
                    <?php wp_nonce_field('ucp_save_manual_sub', 'ucp_manual_sub_nonce'); ?>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                        <div style="grid-column: 1 / -1; position: relative;">
                            <label>اختر المستخدم:</label>
                            <!-- Hidden field that holds the actual value sent to PHP -->
                            <input type="hidden" id="ucp_manual_user" name="ucp_manual_user" required>
                            <!-- Visible search input -->
                            <input type="text" id="ucp_user_search_input" autocomplete="off" class="widefat"
                                placeholder="ابحث باسم المستخدم أو البريد الإلكتروني..."
                                style="border: 2px solid #ddd; padding: 8px 10px; border-radius:6px;">
                            <!-- Results dropdown -->
                            <div id="ucp_user_search_results" style="display:none; position:absolute; z-index:99999;
                                background:#fff; border:1px solid #ccc; border-radius:6px; width:100%;
                                max-height:200px; overflow-y:auto; box-shadow:0 4px 15px rgba(0,0,0,0.15); top:100%; left:0;"></div>
                            <p style="font-size:11px; color:#999; margin:4px 0 0;">ابحث بالاسم أو البريد الإلكتروني</p>
                        </div>
                        <div>
                            <label>اختر الباقة:</label>
                            <select id="ucp_manual_plan" name="ucp_manual_plan" class="widefat">
                                <?php 
                                $plans = get_option('ucp_subscription_plans', []);
                                foreach ($plans as $plan) echo "<option value='{$plan['name_ar']}'>{$plan['name_ar']}</option>";
                                ?>
                            </select>
                        </div>
                        <div>
                            <label>الحالة:</label>
                            <select id="ucp_manual_status" name="ucp_manual_status" class="widefat">
                                <option value="active">نشط</option>
                                <option value="paused">موقوف مؤقتاً</option>
                                <option value="expired">منتهي</option>
                            </select>
                        </div>
                        <div style="grid-column: 1 / -1;">
                            <label>تاريخ الانتهاء:</label>
                            <input type="date" id="ucp_manual_expiry" name="ucp_manual_expiry" class="widefat">
                        </div>
                        
                        <div style="grid-column: 1 / -1; border-top: 1px solid #eee; margin-top: 10px; padding-top: 10px;">
                            <strong>بيانات الملف الطبي (اختياري)</strong>
                        </div>
                        <div>
                            <label>الاسم الكامل:</label>
                            <input type="text" id="ucp_manual_name" name="ucp_manual_name" class="widefat">
                        </div>
                        <div>
                            <label>رقم الهوية:</label>
                            <input type="text" id="ucp_manual_id" name="ucp_manual_id" class="widefat">
                        </div>
                        <div>
                            <label>رقم الجوال:</label>
                            <input type="text" id="ucp_manual_mobile" name="ucp_manual_mobile" class="widefat">
                        </div>
                        <div>
                            <label>النوع:</label>
                            <select id="ucp_manual_gender" name="ucp_manual_gender" class="widefat">
                                <option value="">اختيار</option>
                                <option value="ذكر">ذكر</option>
                                <option value="أنثى">أنثى</option>
                            </select>
                        </div>
                        <div>
                            <label>الوزن (كغ):</label>
                            <input type="number" id="ucp_manual_weight" name="ucp_manual_weight" class="widefat">
                        </div>
                        <div>
                            <label>الطول (سم):</label>
                            <input type="number" id="ucp_manual_height" name="ucp_manual_height" class="widefat">
                        </div>
                        <div>
                            <label>تاريخ الميلاد:</label>
                            <input type="date" id="ucp_manual_dob" name="ucp_manual_dob" class="widefat">
                        </div>
                        <div>
                            <label>المدينة:</label>
                            <input type="text" id="ucp_manual_city" name="ucp_manual_city" class="widefat">
                        </div>

                        <div style="grid-column: 1 / -1; border-top: 1px solid #eee; margin-top: 10px; padding-top: 10px;">
                            <label>الملاحظات الإدارية (لا يراها المشترك):</label>
                            <textarea id="ucp_manual_notes" name="ucp_manual_notes" class="widefat" rows="2"></textarea>
                        </div>
                        <div style="grid-column: 1 / -1;">
                            <label>رسالة للمشترك (إشعار بالتطبيق):</label>
                            <textarea id="ucp_manual_notify" name="ucp_manual_notify" class="widefat" rows="2" placeholder="اكتب هنا إذا أردت تنبيه المشترك بخصوص هذا التعديل..."></textarea>
                        </div>
                    </div>
                    <div style="text-align: right; margin-top: 20px;">
                        <button type="button" class="button" onclick="document.getElementById('ucp-manual-sub-modal').style.display='none'">إلغاء</button>
                        <button type="submit" class="button button-primary">حفظ التغييرات</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Medical Profile Modal -->
        <div id="ucp-medical-modal" style="display:none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 9999;">
            <div style="background: #fff; width: 500px; margin: 100px auto; padding: 20px; border-radius: 10px;">
                <h3>الملف الطبي للمشترك</h3>
                <table class="form-table" id="ucp-medical-data-table">
                </table>
                <p style="text-align: right;">
                    <button type="button" class="button" onclick="document.getElementById('ucp-medical-modal').style.display='none'">إغلاق</button>
                </p>
            </div>
        </div>

        <!-- Logs Modal -->
        <div id="ucp-logs-modal" style="display:none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 9999;">
            <div style="background: #fff; width: 600px; margin: 100px auto; padding: 20px; border-radius: 10px;">
                <h3>سجل اشتراك المستخدم</h3>
                <ul id="ucp-logs-list" style="max-height: 400px; overflow-y: auto; background: #f9f9f9; padding: 10px; border: 1px solid #ddd;">
                </ul>
                <p style="text-align: right;">
                    <button type="button" class="button" onclick="document.getElementById('ucp-logs-modal').style.display='none'">إغلاق</button>
                </p>
            </div>
        </div>
        <script>
        jQuery(document).ready(function($){
            $(document).on('click', '#ucp-run-manual-cron', function(){
                var btn = $(this);
                if(!confirm('سيتم فحص جميع الاشتراكات الآن (تنبيهات الانتهاء + إنشاء الفواتير + تحويل المنتهية). هل تريد الاستمرار؟')) return;
                btn.prop('disabled', true).text('جاري الفحص...');
                $.post(ajaxurl, { action: 'ucp_run_manual_cron' }, function(res){
                    btn.prop('disabled', false).html('<span class="dashicons dashicons-update" style="margin-top:4px;"></span> فحص يدوي للاشتراكات');
                    if(res.success) alert(res.data);
                    else alert('خطأ: ' + res.data);
                    location.reload();
                });
            });

            $(document).on('click', '.ucp-test-notif', function(){

                var btn = $(this);
                if(!confirm('هل أنت متأكد من إرسال بريد تجريبي؟')) return;
                $.post(ajaxurl, {
                    action: 'ucp_test_notification',
                    user_id: btn.data('userid'),
                    nonce: btn.data('nonce')
                }, function(res){
                    if(res.success) alert(res.data);
                    else alert('خطأ: ' + res.data);
                });
            });

            $(document).on('click', '.ucp-edit-user-sub', function(){
                var email = $(this).data('email');
                var plan = $(this).data('plan');
                var status = $(this).data('status');
                var expiry = $(this).data('expiry');
                var notes = $(this).data('notes');
                
                $('#ucp_manual_user').val(email);
                $('#ucp_manual_plan').val(plan);
                $('#ucp_manual_status').val(status);
                $('#ucp_manual_expiry').val(expiry);
                $('#ucp_manual_notes').val(notes);
                $('#ucp_manual_notify').val('');
                $('#ucp-manual-sub-modal').show();
            });

            $(document).on('click', '.ucp-view-medical', function(){
                var profile = $(this).data('profile');
                var html = '';
                if(profile && typeof profile === 'object' && Object.keys(profile).length > 0) {
                    $.each(profile, function(key, val) {
                        html += '<tr><th style="width:150px;">'+key+'</th><td>'+(val ? val : '-')+'</td></tr>';
                    });
                } else {
                    html = '<tr><td>لا يوجد بيانات طبية مسجلة لهذا المشترك.</td></tr>';
                }
                $('#ucp-medical-data-table').html(html);
                $('#ucp-medical-modal').show();
            });

            $(document).on('click', '.ucp-view-logs', function(){
                var logs = $(this).data('logs');
                var html = '';
                if(logs && logs.length > 0) {
                    // Reverse to show newest first
                    logs.reverse().forEach(function(log) {
                        html += '<li style="margin-bottom: 10px; border-bottom: 1px solid #eee; padding-bottom: 5px;">';
                        html += '<strong style="color:#2271b1;">'+log.date+'</strong><br>';
                        html += log.action + ' <small style="color:gray;">(بواسطة: '+log.by+')</small>';
                        html += '</li>';
                    });
                } else {
                    html = '<li>لا توجد سجلات سابقة.</li>';
                }
                $('#ucp-logs-list').html(html);
                $('#ucp-logs-modal').show();
            });
        });
        </script>
        <?php
    }

    public function enqueue_assets($hook) {
        if ( ! in_array( $hook, [ 'post.php', 'post-new.php', 'edit-tags.php', 'term.php', 'settings_page_ucp-promotions', 'ucp-app_page_ucp-subscriptions' ] ) ) return;
        wp_enqueue_media();
    }

    public function ajax_search_users() {
        if ( ! current_user_can('manage_options') ) wp_die();
        $term = sanitize_text_field( $_GET['term'] ?? '' );
        $users = get_users([
            'search'         => '*' . $term . '*',
            'search_columns' => ['user_login', 'user_email', 'display_name'],
            'number'         => 20,
        ]);
        $results = [];
        foreach ($users as $u) {
            $results[] = [
                'id'   => $u->user_login, // send login for lookup
                'text' => $u->display_name . ' (' . $u->user_email . ')'
            ];
        }
        wp_send_json(['results' => $results]);
    }

    public function ajax_test_notification() {
        if ( ! current_user_can('manage_options') || ! check_ajax_referer('ucp_test_notif', 'nonce', false) ) {
            wp_send_json_error('غير مصرح');
        }
        $user_id = intval($_POST['user_id']);
        $user = get_user_by('id', $user_id);
        if ( ! $user ) {
            wp_send_json_error('المستخدم غير موجود');
        }

        $medical_profile = get_user_meta($user_id, 'ucp_medical_profile', true) ?: [];
        $email_to = !empty($medical_profile['البريد']) ? $medical_profile['البريد'] : $user->user_email;

        $message = "هذه رسالة تجريبية للتحقق من عمل نظام الإشعارات.\n\nعزيزي {$user->display_name}، اشتراكك سينتهي قريباً. بادر بالتجديد لتجنب انقطاع الخدمة.";

        if ( class_exists('UCP_Subscriptions') ) {
            $subs = new UCP_Subscriptions();
            $subs->add_user_notification($user_id, $message, 'تجريبي: تنبيه انتهاء الاشتراك');
            wp_send_json_success('✅ تم إرسال البريد التجريبي إلى: ' . esc_html($email_to));
        } else {
            wp_send_json_error('كلاس UCP_Subscriptions غير محمّل');
        }
    }

    public function render_js() {

        ?>
        <script>
        jQuery(document).ready(function($){

            // ===== Media Uploader =====
            var frame;
            $(document).on('click', '.ucp_upload_button', function(e){
                e.preventDefault();
                var btn = $(this);
                frame = wp.media({ title: 'اختر صورة', button: { text: 'استخدام الصورة' }, multiple: false });
                frame.on('select', function() {
                    var attachment = frame.state().get('selection').first().toJSON();
                    btn.siblings('input[type="hidden"]').val(attachment.id);
                    btn.siblings('.preview').html('<img src="'+attachment.url+'" style="max-width:200px;display:block;">');
                });
                frame.open();
            });

            // ===== Custom User Live Search =====
            var searchTimer = null;

            function renderResults(users) {
                var $results = $('#ucp_user_search_results');
                $results.empty();
                if (!users || users.length === 0) {
                    $results.html('<div style="padding:10px 14px; color:#999; font-size:13px;">لا توجد نتائج</div>');
                    $results.show();
                    return;
                }
                $.each(users, function(i, u) {
                    $('<div>')
                        .text(u.text)
                        .attr('data-value', u.id)
                        .css({
                            padding: '10px 14px',
                            cursor: 'pointer',
                            fontSize: '13px',
                            borderBottom: '1px solid #f0f0f0',
                            background: '#fff',
                        })
                        .hover(
                            function(){ $(this).css('background', '#f0f7ff'); },
                            function(){ $(this).css('background', '#fff'); }
                        )
                        .on('click', function() {
                            var val = $(this).data('value');
                            var label = $(this).text();
                            $('#ucp_manual_user').val(val);
                            $('#ucp_user_search_input').val(label).css('border-color', '#46b450');
                            $results.hide().empty();
                        })
                        .appendTo($results);
                });
                $results.show();
            }

            $(document).on('input', '#ucp_user_search_input', function(){
                var term = $(this).val().trim();
                $('#ucp_manual_user').val(''); // clear hidden on new search
                $(this).css('border-color', '#ddd');
                clearTimeout(searchTimer);

                if (term.length < 1) {
                    $('#ucp_user_search_results').hide().empty();
                    return;
                }

                $('#ucp_user_search_results')
                    .html('<div style="padding:10px 14px; color:#999; font-size:13px;">جاري البحث...</div>')
                    .show();

                searchTimer = setTimeout(function(){
                    $.get(ajaxurl, { action: 'ucp_search_users', term: term }, function(data){
                        renderResults(data.results || []);
                    });
                }, 300);
            });

            // Close results on outside click
            $(document).on('click', function(e){
                if (!$(e.target).closest('#ucp_user_search_input, #ucp_user_search_results').length) {
                    $('#ucp_user_search_results').hide();
                }
            });

            // Reset search widget when modal opens fresh
            $(document).on('click', '#ucp-open-manual-sub', function(){
                $('#ucp_manual_user').val('');
                $('#ucp_user_search_input').val('').css('border-color', '#ddd');
                $('#ucp_user_search_results').hide().empty();
            });

        });
        </script>
        <?php
    }


    /**
     * مزامنة الباقات مع منتجات ووكومرس تلقائياً
     */
    public function sync_plans_with_wc( $old_value, $new_value ) {
        if ( ! is_array( $new_value ) ) return;

        foreach ( $new_value as $index => $plan ) {
            $product_id = $plan['product_id'] ?? 0;
            
            // إذا كان المنتج موجوداً، نقوم بتحديث سعره واسمه
            $post = get_post( $product_id );
            if ( ! $product_id || ! $post || $post->post_type !== 'product' ) {
                // إنشاء منتج جديد
                $product_id = wp_insert_post([
                    'post_title'   => $plan['name_ar'],
                    'post_content' => "باقة اشتراك تطبيق UCP - " . $plan['name_en'],
                    'post_status'  => 'publish',
                    'post_type'    => 'product',
                ]);
            }

            if ( $product_id ) {
                // تحديث الـ ID في الخطة ليتم حفظه
                if ( ! isset( $plan['product_id'] ) || $plan['product_id'] != $product_id ) {
                    $new_value[$index]['product_id'] = $product_id;
                }

                // تعيين خصائص المنتج كمنتج افتراضي ومخفي عن المتجر
                update_post_meta( $product_id, '_virtual', 'yes' );
                update_post_meta( $product_id, '_regular_price', $plan['price'] );
                update_post_meta( $product_id, '_price', $plan['price'] );
                update_post_meta( $product_id, '_ucp_is_subscription', 'yes' );
                update_post_meta( $product_id, '_ucp_sub_duration', $plan['duration'] );
                
                // إخفاء المنتج تماماً من الكتالوج والبحث (Catalog Visibility: Hidden)
                wp_set_object_terms( $product_id, ['exclude-from-catalog', 'exclude-from-search'], 'product_visibility' );
            }
        }
        
        // لمنع الدوران اللانهائي (Infinite Loop)، نتحقق إذا تغيرت القيم
        if ( $new_value !== get_option('ucp_subscription_plans') ) {
            remove_action( 'update_option_ucp_subscription_plans', [ $this, 'sync_plans_with_wc' ], 10 );
            update_option( 'ucp_subscription_plans', $new_value );
            add_action( 'update_option_ucp_subscription_plans', [ $this, 'sync_plans_with_wc' ], 10, 2 );
        }
    }
}
