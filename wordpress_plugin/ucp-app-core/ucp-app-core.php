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

// تشغيل النظام
add_action( 'plugins_loaded', 'ucp_init_app_core' );

function ucp_init_app_core() {
    new UCP_Admin();
    new UCP_API();
    new UCP_FCM();
    new UCP_Slider();
    new UCP_DeepLink();
}
