<?php
if ( ! defined( 'ABSPATH' ) ) exit;

/**
 * UCP My Account - Subscription Tab
 *
 * Strategy: Use query parameter (?ucp_section=subscription) instead of
 * WooCommerce rewrite endpoints to avoid 404 issues with rewrite rules.
 */
class UCP_MyAccount {

    public function __construct() {
        // إضافة تبويب "اشتراكي" بـ URL مباشر (بدون Endpoint / Rewrite Rules)
        add_filter( 'woocommerce_account_menu_items', [ $this, 'add_subscription_tab' ] );
        add_filter( 'woocommerce_get_myaccount_page_permalink', [ $this, 'maybe_redirect_tab_url' ] );

        // اعتراض صفحة My Account وحقن المحتوى عند وجود ?ucp_section=subscription
        add_action( 'woocommerce_account_content', [ $this, 'maybe_render_subscription_content' ], 1 );

        // إضافة شورتكود مستقل [ucp_my_subscription]
        add_shortcode( 'ucp_my_subscription', [ $this, 'render_subscription_content' ] );
        
        // تسجيل ملفات CSS
        add_action( 'wp_enqueue_scripts', [ $this, 'enqueue_styles' ] );
    }

    public function enqueue_styles() {
        if ( is_account_page() ) {
            wp_enqueue_style( 'ucp-myaccount-css', plugins_url( 'assets/css/ucp-myaccount.css', dirname(__FILE__) ), [], '1.2.0' );
        }
    }

    /**
     * إضافة تبويب "اشتراكي" لقائمة حساب العميل
     */
    public function add_subscription_tab( $items ) {
        $logout = $items['customer-logout'] ?? null;
        unset( $items['customer-logout'] );

        // استخدام مفتاح خاص غير مرتبط بـ Endpoint
        $items['ucp-my-sub-tab'] = '🏅 اشتراكي';

        if ( $logout ) {
            $items['customer-logout'] = $logout;
        }
        return $items;
    }

    /**
     * تعديل رابط تبويب "اشتراكي" ليشير لصفحة حسابي مع باراميتر
     */
    public function maybe_redirect_tab_url( $url ) {
        return $url;
    }

    /**
     * تعديل HTML التبويب ليحتوي على رابط صحيح بباراميتر
     */
    public function __construct_late() {}

    /**
     * اعتراض محتوى My Account عند وجود الباراميتر
     */
    public function maybe_render_subscription_content() {
        // تحقق إذا كان الطلب الحالي هو تبويب الاشتراك
        if ( isset( $_GET['ucp_section'] ) && $_GET['ucp_section'] === 'subscription' ) {
            // منع WooCommerce من عرض محتواه الافتراضي
            remove_all_actions( 'woocommerce_account_content' );
            echo $this->render_subscription_content();
        }
    }

    /**
     * عرض محتوى صفحة "اشتراكي" (يُستخدم أيضاً كـ Shortcode)
     */
    public function render_subscription_content( $atts = [] ) {
        if ( ! is_user_logged_in() ) {
            return '<p>يرجى <a href="' . esc_url( wc_get_page_permalink('myaccount') ) . '">تسجيل الدخول</a> أولاً.</p>';
        }

        $user_id      = get_current_user_id();
        $status       = get_user_meta( $user_id, 'ucp_subscription_status', true );
        $plan         = get_user_meta( $user_id, 'ucp_subscription_plan_id', true );
        $start        = get_user_meta( $user_id, 'ucp_subscription_start', true );
        $expiry       = get_user_meta( $user_id, 'ucp_subscription_expiry', true );
        $notifications = get_user_meta( $user_id, 'ucp_user_notifications', true ) ?: [];
        $checkout_url = get_option( 'ucp_subscription_checkout_page', wc_get_checkout_url() );

        $days_left = 0;
        $status_label = 'نشط';
        $status_desc  = 'اشتراكك يعمل بشكل جيد';
        $status_color = '#10b981';
        $status_bg    = '#ecfdf5';
        $status_icon  = 'dashicons-yes';
        $percent      = 0;
        $order_id     = get_user_meta($user_id, 'ucp_subscription_order_id', true) ?: '00000';

        if ( $status === 'paused' ) {
            $remaining_secs = (int) get_user_meta( $user_id, 'ucp_paused_remaining_seconds', true );
            $days_left = max( 0, ceil( $remaining_secs / 86400 ) );
            $status_label = 'موقوف مؤقتاً';
            $status_desc  = 'يتطلب اتخاذ إجراء للتفعيل';
            $status_color = '#f97316';
            $status_bg    = '#fff7ed';
            $status_icon  = 'dashicons-controls-pause';
        } elseif ( $status === 'expired' ) {
            $days_left = 0;
            $status_label = 'منتهي';
            $status_desc  = 'انتهت مدة اشتراكك، يرجى التجديد';
            $status_color = '#ef4444';
            $status_bg    = '#fef2f2';
            $status_icon  = 'dashicons-warning';
        } else {
            $days_left = $expiry ? max( 0, ceil( ( $expiry - time() ) / 86400 ) ) : 30;
            $status_label = 'نشط';
            $status_desc  = 'اشتراكك مفعل وتحت الخدمة';
            $status_color = '#10b981';
            $status_bg    = '#ecfdf5';
            $status_icon  = 'dashicons-yes';
        }

        // Orange primary color
        $primary_orange = '#f97316';

        $order_id = get_user_meta($user_id, 'ucp_subscription_order_id', true);
        $renew_product_id = 0;
        
        if ( $order_id ) {
            $order = wc_get_order( $order_id );
            if ( $order ) {
                foreach ( $order->get_items() as $item ) {
                    $pid = $item->get_product_id();
                    if ( get_post_meta( $pid, '_ucp_is_subscription', true ) === 'yes' ) {
                        $renew_product_id = $pid;
                        break;
                    }
                }
            }
        }

        // If we found the product, direct to checkout with add-to-cart
        // Otherwise, send to plans page
        if ( $renew_product_id ) {
            $renew_url = add_query_arg( 'add-to-cart', $renew_product_id, wc_get_checkout_url() );
        } else {
            $renew_url = site_url( '/subscriptions' ); // Common fallback path
        }

        // Orange primary color
        $primary_orange = '#f97316';

        // Percentage for visual
        $total_duration = 30 * 86400; 
        if ($start && $expiry) {
            $total_duration = max(86400, $expiry - strtotime($start));
        }
        $elapsed = time() - ($expiry - $total_duration);
        $percent = min(100, max(0, round(($elapsed / $total_duration) * 100)));

        ob_start();
        ?>
        <div id="ucp-billing-root" style="--primary-orange: <?php echo $primary_orange; ?>; --status-color: <?php echo $status_color; ?>; --status-bg: <?php echo $status_bg; ?>;">

            <!-- Header Section -->
            <div class="ucp-header-stack">
                <div class="ucp-header-info">
                    <h1>اشتراكي</h1>
                    <p>أهلاً بك في لوحة تحكم اشتراكك الخاص</p>
                </div>
                <a href="<?php echo esc_url($renew_url); ?>" class="ucp-renew-btn-main">
                    <span class="dashicons dashicons-update"></span>
                    تجديد الاشتراك الآن
                </a>
            </div>

            <!-- Dashboard Grid -->
            <div class="ucp-flex-col-mobile ucp-dashboard-grid">
                
                <!-- Main Card: Subscription Status -->
                <div class="ucp-card-mobile ucp-status-card">
                    <div class="ucp-order-info-top">
                        <span class="ucp-order-label">رقم الطلب الأخير</span>
                        <span class="ucp-order-id">#<?php echo esc_html($order_id); ?></span>
                    </div>

                    <div class="ucp-status-header">
                        <div class="ucp-status-icon-box">
                            <span class="dashicons <?php echo $status_icon; ?>"></span>
                        </div>
                        <div class="ucp-status-text">
                            <div class="ucp-status-title-row">
                                <h2>حالة الاشتراك: <?php echo $status_label; ?></h2>
                                <span class="ucp-order-badge">طلب #<?php echo esc_html($order_id); ?></span>
                            </div>
                            <p><?php echo $status_desc; ?></p>
                        </div>
                    </div>

                    <div class="ucp-stats-row">
                        <div class="ucp-stat-box">
                            <span class="dashicons dashicons-products ucp-icon-plan"></span>
                            <span class="ucp-stat-label">الباقة الحالية</span>
                            <span class="ucp-stat-value">باقة <?php echo $plan ? esc_html($plan) : '3'; ?></span>
                        </div>
                        <div class="ucp-stat-box">
                            <span class="dashicons dashicons-clock ucp-icon-time"></span>
                            <span class="ucp-stat-label">الأيام المتبقية</span>
                            <span class="ucp-stat-value"><?php echo $days_left; ?> يوم</span>
                        </div>
                    </div>
                </div>

                <!-- Secondary Card: Timeframe & Usage -->
                <div class="ucp-card-mobile ucp-time-card">
                    <h3 class="ucp-card-title">
                        <span class="dashicons dashicons-chart-area"></span>
                        تفاصيل الاستهلاك والوقت
                    </h3>
                    
                    <div class="ucp-time-rows">
                        <div class="ucp-time-row">
                            <span class="ucp-time-label">تاريخ البداية</span>
                            <span class="ucp-time-value ucp-start-date"><?php echo $start ? esc_html(date_i18n('j M Y', strtotime($start))) : '—'; ?></span>
                        </div>
                        <div class="ucp-time-row">
                            <span class="ucp-time-label">تاريخ الانتهاء</span>
                            <span class="ucp-time-value ucp-expiry-date"><?php echo $expiry ? esc_html(date_i18n('j M Y', $expiry)) : '—'; ?></span>
                        </div>
                    </div>

                    <div class="ucp-usage-section">
                        <div class="ucp-usage-header">
                            <span class="ucp-usage-label">الاستهلاك الحالي</span>
                            <span class="ucp-usage-percent"><?php echo $percent; ?>%</span>
                        </div>
                        <div class="ucp-progress-container">
                            <div class="ucp-progress-bar-fill" style="width: <?php echo $percent; ?>% !important;"></div>
                        </div>
                        <p class="ucp-usage-footer">متبقي لك <?php echo $days_left; ?> يوم من أصل 30 يوم</p>
                    </div>
                </div>

            </div>

            <!-- Promotion Banner -->
            <div class="ucp-promo-banner">
                <div class="ucp-promo-bg-icon">
                    <span class="dashicons dashicons-shield-alt"></span>
                </div>
                <div class="ucp-promo-content">
                    <div class="ucp-promo-tag">عرض الترقية</div>
                    <h3>وفر أكثر مع الباقة السنوية</h3>
                    <p>احصل على شهرين مجاناً عند الترقية الآن. لا تفوت فرصة التوفير والبدء في رحلتك الصحية الطويلة.</p>
                </div>
                <div class="ucp-promo-actions">
                    <a href="<?php echo esc_url($renew_url); ?>" class="ucp-promo-btn">ترقية الآن</a>
                </div>
            </div>

            <!-- Invoices Section -->
            <div class="ucp-invoices-section" style="margin-top: 30px; background: #fff; border-radius: 12px; border: 1px solid #e5e7eb; overflow: hidden;">
                <div style="padding: 20px; border-bottom: 1px solid #e5e7eb; display: flex; justify-content: space-between; align-items: center;">
                    <h3 style="margin: 0; font-size: 18px; color: #111827;">فواتير الاشتراكات</h3>
                    <span class="dashicons dashicons-media-text" style="color: #9ca3af;"></span>
                </div>
                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; text-align: right;">
                        <thead>
                            <tr style="background: #f9fafb;">
                                <th style="padding: 12px 20px; color: #4b5563; font-weight: 600; font-size: 14px;">رقم الفاتورة</th>
                                <th style="padding: 12px 20px; color: #4b5563; font-weight: 600; font-size: 14px;">التاريخ</th>
                                <th style="padding: 12px 20px; color: #4b5563; font-weight: 600; font-size: 14px;">الحالة</th>
                                <th style="padding: 12px 20px; color: #4b5563; font-weight: 600; font-size: 14px;">الإجمالي</th>
                                <th style="padding: 12px 20px; color: #4b5563; font-weight: 600; font-size: 14px;">الإجراء</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php 
                            $customer_orders = wc_get_orders([
                                'customer' => $user_id,
                                'limit'    => 20, // زيادة الحد لضمان ظهور كافة الفواتير الأخيرة
                                'status'   => ['pending', 'processing', 'completed', 'on-hold', 'failed'], // شمول كافة الحالات
                            ]);

                            $sub_orders_found = false;
                            foreach ( $customer_orders as $order ) : 
                                $is_sub_order = false;
                                foreach ( $order->get_items() as $item ) {
                                    $product_id = $item->get_product_id();
                                    // التحقق من أن المنتج هو باقة اشتراك
                                    if ( get_post_meta( $product_id, '_ucp_is_subscription', true ) === 'yes' ) {
                                        $is_sub_order = true;
                                        break;
                                    }
                                }

                                if ( ! $is_sub_order ) continue;
                                $sub_orders_found = true;
                                $order_status = $order->get_status();
                                $status_name = wc_get_order_status_name($order_status);
                                ?>
                                <tr style="border-bottom: 1px solid #f3f4f6;">
                                    <td style="padding: 15px 20px; font-weight: 500; color: #111827;">
                                        #<?php echo $order->get_order_number(); ?>
                                        <?php if ( $order_status === 'pending' ) : ?>
                                            <span style="font-size:10px; background:#fff7ed; color:#f97316; padding:2px 5px; border-radius:4px; margin-right:5px;">تجديد</span>
                                        <?php endif; ?>
                                    </td>
                                    <td style="padding: 15px 20px; color: #6b7280; font-size: 14px;"><?php echo wc_format_datetime( $order->get_date_created() ); ?></td>
                                    <td style="padding: 15px 20px;">
                                        <span style="padding: 4px 10px; border-radius: 20px; font-size: 12px; background: <?php echo $order_status === 'completed' ? '#ecfdf5' : ($order_status === 'pending' ? '#fff7ed' : '#f3f4f6'); ?>; color: <?php echo $order_status === 'completed' ? '#10b981' : ($order_status === 'pending' ? '#f97316' : '#6b7280'); ?>;">
                                            <?php echo esc_html($status_name); ?>
                                        </span>
                                    </td>
                                    <td style="padding: 15px 20px; font-weight: 600; color: #111827;"><?php echo $order->get_formatted_order_total(); ?></td>
                                    <td style="padding: 15px 20px;">
                                        <?php if ( $order->needs_payment() ) : ?>
                                            <a href="<?php echo esc_url( $order->get_checkout_payment_url() ); ?>" style="color: #f97316; text-decoration: none; font-weight: 600; font-size: 14px;">دفع الآن</a>
                                        <?php else : ?>
                                            <a href="<?php echo esc_url( $order->get_view_order_url() ); ?>" style="color: #2563eb; text-decoration: none; font-weight: 500; font-size: 14px;">عرض</a>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                            
                            <?php if ( ! $sub_orders_found ) : ?>
                                <tr>
                                    <td colspan="5" style="padding: 40px; text-align: center; color: #9ca3af;">لا توجد فواتير اشتراكات سابقة.</td>
                                </tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>

        </div>
        <?php
        return ob_get_clean();
    }
}
/**
 * تخصيص رابط تبويب "اشتراكي" في قائمة My Account
 * يتم استخدام filter خاص بـ WooCommerce لتعديل روابط القائمة
 */
add_filter( 'woocommerce_get_endpoint_url', function( $url, $endpoint, $value, $permalink ) {
    if ( $endpoint === 'ucp-my-sub-tab' ) {
        return add_query_arg( 'ucp_section', 'subscription', wc_get_page_permalink('myaccount') );
    }
    return $url;
}, 10, 4 );
