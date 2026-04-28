<?php
/**
 * Plugin Name: UCP App Core
 * Plugin URI: https://ucpksa.com
 * Description: النظام المتكامل لربط تطبيق Flutter بموقع ووردبريس (السلايدر، الإشعارات، وتحديثات التطبيق).
 * Version: 1.2.0
 * Author: UCP Team
 * Text Domain: ucp-app-core
 */

if ( ! defined( 'ABSPATH' ) ) exit;

// تعريف الثوابت
define( 'UCP_VERSION', '1.2.0' );
define( 'UCP_PATH', plugin_dir_path( __FILE__ ) );

// تحميل الملفات الفرعية
require_once UCP_PATH . 'includes/class-ucp-admin.php';
require_once UCP_PATH . 'includes/class-ucp-api.php';
require_once UCP_PATH . 'includes/class-ucp-fcm.php';
require_once UCP_PATH . 'includes/class-ucp-slider.php';
require_once UCP_PATH . 'includes/class-ucp-deeplink.php';
require_once UCP_PATH . 'includes/class-ucp-banner.php';
require_once UCP_PATH . 'includes/class-ucp-order-filter.php';
require_once UCP_PATH . 'includes/class-ucp-subscriptions.php';
require_once UCP_PATH . 'includes/class-ucp-shortcodes.php';
require_once UCP_PATH . 'includes/class-ucp-myaccount.php';

// تشغيل النظام
add_action( 'plugins_loaded', 'ucp_init_app_core' );

function ucp_init_app_core() {
    new UCP_Admin();
    new UCP_API();
    new UCP_FCM();
    new UCP_Slider();
    new UCP_DeepLink();
    new UCP_Banner();
    new UCP_Order_Filter();
    new UCP_Subscriptions();
    new UCP_Shortcodes();
    new UCP_MyAccount();
}

// تسجيل مهام الـ Cron ومسح الـ Rewrite Rules عند تفعيل الإضافة
register_activation_hook( __FILE__, 'ucp_app_core_activate' );
function ucp_app_core_activate() {
    // جدولة المهمة اليومية
    if ( ! wp_next_scheduled( 'ucp_daily_subscription_check' ) ) {
        wp_schedule_event( time(), 'daily', 'ucp_daily_subscription_check' );
    }
    // تسجيل الـ Endpoint وتحديث قواعد الروابط
    add_rewrite_endpoint( 'ucp-subscription', EP_ROOT | EP_PAGES );
    flush_rewrite_rules();
}

// إزالة مهام الـ Cron عند تعطيل الإضافة
register_deactivation_hook( __FILE__, 'ucp_app_core_deactivate' );
function ucp_app_core_deactivate() {
    wp_clear_scheduled_hook( 'ucp_daily_subscription_check' );
}
