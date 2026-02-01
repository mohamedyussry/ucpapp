<?php
/**
 * Plugin Name: App Core
 * Plugin URI: https://mohamedyussry.github.io/
 * Description: إضافة خيارات مخصصة لتصنيفات WooCommerce للتحكم في سلايدر تطبيق Flutter (إظهار في السلايدر + صورة مخصصة للسلايدر).
 * Version: 1.1.0
 * Author: Mohamed Yussry
 * Author URI: https://mohamedyussry.github.io/
 * Text Domain: ucp-slider
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; 
}

/**
 * إضافة حقول مخصصة عند إنشاء تصنيف جديد
 */
function ucp_add_category_slider_fields() {
	?>
	<div class="form-field term-slider-wrap">
		<label for="ucp_show_in_slider"><?php _e( 'إظهار في سلايدر التطبيق', 'ucp-slider' ); ?></label>
		<input type="checkbox" name="ucp_show_in_slider" id="ucp_show_in_slider" value="1">
		<p class="description"><?php _e( 'إذا تم التحديد، سيظهر هذا التصنيف في السلايدر العلوي للتطبيق.', 'ucp-slider' ); ?></p>
	</div>
	<div class="form-field term-slider-image-wrap">
		<label for="ucp_slider_image_id"><?php _e( 'صورة السلايدر المخصصة (أبعاد 16:9)', 'ucp-slider' ); ?></label>
		<input type="hidden" id="ucp_slider_image_id" name="ucp_slider_image_id" value="">
		<div id="ucp_slider_image_preview" style="margin-bottom:10px;"></div>
		<button type="button" class="button ucp_upload_image_button"><?php _e( 'رفع/اختيار صورة', 'ucp-slider' ); ?></button>
		<button type="button" class="button ucp_remove_image_button" style="display:none;"><?php _e( 'إزالة الصورة', 'ucp-slider' ); ?></button>
	</div>
	<?php
}
add_action( 'product_cat_add_form_fields', 'ucp_add_category_slider_fields', 10 );

/**
 * إضافة حقول مخصصة عند تعديل تصنيف موجود
 */
function ucp_edit_category_slider_fields( $term ) {
	$show_in_slider = get_term_meta( $term->term_id, 'ucp_show_in_slider', true );
	$image_id       = get_term_meta( $term->term_id, 'ucp_slider_image_id', true );
	$image_url      = $image_id ? wp_get_attachment_url( $image_id ) : '';
	?>
	<tr class="form-field term-slider-wrap">
		<th scope="row"><label for="ucp_show_in_slider"><?php _e( 'إظهار في سلايدر التطبيق', 'ucp-slider' ); ?></label></th>
		<td>
			<input type="checkbox" name="ucp_show_in_slider" id="ucp_show_in_slider" value="1" <?php checked( $show_in_slider, '1' ); ?>>
			<p class="description"><?php _e( 'إذا تم التحديد، سيظهر هذا التصنيف في السلايدر العلوي للتطبيق.', 'ucp-slider' ); ?></p>
		</td>
	</tr>
	<tr class="form-field term-slider-image-wrap">
		<th scope="row"><label for="ucp_slider_image_id"><?php _e( 'صورة السلايدر المخصصة (أبعاد 16:9)', 'ucp-slider' ); ?></label></th>
		<td>
			<input type="hidden" id="ucp_slider_image_id" name="ucp_slider_image_id" value="<?php echo esc_attr( $image_id ); ?>">
			<div id="ucp_slider_image_preview" style="margin-bottom:10px;">
				<?php if ( $image_url ) : ?>
					<img src="<?php echo esc_url( $image_url ); ?>" style="max-width:300px; display:block;">
				<?php endif; ?>
			</div>
			<button type="button" class="button ucp_upload_image_button"><?php _e( 'رفع/اختيار صورة', 'ucp-slider' ); ?></button>
			<button type="button" class="button ucp_remove_image_button" style="<?php echo $image_url ? '' : 'display:none;'; ?>"><?php _e( 'إزالة الصورة', 'ucp-slider' ); ?></button>
		</td>
	</tr>
	<?php
}
add_action( 'product_cat_edit_form_fields', 'ucp_edit_category_slider_fields', 10 );

/**
 * حفظ البيانات المخصصة
 */
function ucp_save_category_slider_fields( $term_id ) {
	update_term_meta( $term_id, 'ucp_show_in_slider', isset( $_POST['ucp_show_in_slider'] ) ? '1' : '0' );
	if ( isset( $_POST['ucp_slider_image_id'] ) ) {
		update_term_meta( $term_id, 'ucp_slider_image_id', sanitize_text_field( $_POST['ucp_slider_image_id'] ) );
	}
}
add_action( 'created_product_cat', 'ucp_save_category_slider_fields', 10 );
add_action( 'edited_product_cat', 'ucp_save_category_slider_fields', 10 );

/**
 * إضافة حقول مخصصة للماركات (إنشاء جديد)
 */
function ucp_add_brand_custom_fields() {
	?>
	<div class="form-field term-app-show-wrap">
		<label for="ucp_show_brand_in_app"><?php _e( 'إظهار في التطبيق', 'ucp-slider' ); ?></label>
		<input type="checkbox" name="ucp_show_brand_in_app" id="ucp_show_brand_in_app" value="1">
		<p class="description"><?php _e( 'تحكم في ظهور هذه الماركة في الصفحة الرئيسية للتطبيق.', 'ucp-slider' ); ?></p>
	</div>
	<div class="form-field term-slider-wrap">
		<label for="ucp_show_brand_in_slider"><?php _e( 'إظهار في سلايدر التطبيق', 'ucp-slider' ); ?></label>
		<input type="checkbox" name="ucp_show_brand_in_slider" id="ucp_show_brand_in_slider" value="1">
		<p class="description"><?php _e( 'إذا تم التحديد، ستظهر هذه الماركة في السلايدر العلوي للتطبيق.', 'ucp-slider' ); ?></p>
	</div>
	<div class="form-field term-slider-image-wrap">
		<label for="ucp_brand_slider_image_id"><?php _e( 'صورة السلايدر المخصصة (أبعاد 16:9)', 'ucp-slider' ); ?></label>
		<input type="hidden" id="ucp_brand_slider_image_id" name="ucp_brand_slider_image_id" value="">
		<div id="ucp_brand_slider_image_preview" style="margin-bottom:10px;"></div>
		<button type="button" class="button ucp_upload_brand_image_button"><?php _e( 'رفع/اختيار صورة', 'ucp-slider' ); ?></button>
		<button type="button" class="button ucp_remove_brand_image_button" style="display:none;"><?php _e( 'إزالة الصورة', 'ucp-slider' ); ?></button>
	</div>
	<?php
}
add_action( 'product_brand_add_form_fields', 'ucp_add_brand_custom_fields', 10 );

/**
 * إضافة حقول مخصصة للماركات (تعديل)
 */
function ucp_edit_brand_custom_fields( $term ) {
	$show_in_app = get_term_meta( $term->term_id, 'ucp_show_brand_in_app', true );
    // افتراضياً نعتبرها غير مفعلة إذا لم تكن هناك قيمة مخزنة بعد
    $show_in_app = ($show_in_app === '') ? '0' : $show_in_app;
	
	$show_in_slider = get_term_meta( $term->term_id, 'ucp_show_brand_in_slider', true );
	$image_id       = get_term_meta( $term->term_id, 'ucp_brand_slider_image_id', true );
	$image_url      = $image_id ? wp_get_attachment_url( $image_id ) : '';
	?>
	<tr class="form-field term-app-show-wrap">
		<th scope="row"><label for="ucp_show_brand_in_app"><?php _e( 'إظهار في التطبيق', 'ucp-slider' ); ?></label></th>
		<td>
			<input type="checkbox" name="ucp_show_brand_in_app" id="ucp_show_brand_in_app" value="1" <?php checked( $show_in_app, '1' ); ?>>
			<p class="description"><?php _e( 'تحكم في ظهور هذه الماركة في الصفحة الرئيسية للتطبيق.', 'ucp-slider' ); ?></p>
		</td>
	</tr>
	<tr class="form-field term-slider-wrap">
		<th scope="row"><label for="ucp_show_brand_in_slider"><?php _e( 'إظهار في سلايدر التطبيق', 'ucp-slider' ); ?></label></th>
		<td>
			<input type="checkbox" name="ucp_show_brand_in_slider" id="ucp_show_brand_in_slider" value="1" <?php checked( $show_in_slider, '1' ); ?>>
			<p class="description"><?php _e( 'إذا تم التحديد، ستظهر هذه الماركة في السلايدر العلوي للتطبيق.', 'ucp-slider' ); ?></p>
		</td>
	</tr>
	<tr class="form-field term-slider-image-wrap">
		<th scope="row"><label for="ucp_brand_slider_image_id"><?php _e( 'صورة السلايدر المخصصة (أبعاد 16:9)', 'ucp-slider' ); ?></label></th>
		<td>
			<input type="hidden" id="ucp_brand_slider_image_id" name="ucp_brand_slider_image_id" value="<?php echo esc_attr( $image_id ); ?>">
			<div id="ucp_brand_slider_image_preview" style="margin-bottom:10px;">
				<?php if ( $image_url ) : ?>
					<img src="<?php echo esc_url( $image_url ); ?>" style="max-width:300px; display:block;">
				<?php endif; ?>
			</div>
			<button type="button" class="button ucp_upload_brand_image_button"><?php _e( 'رفع/اختيار صورة', 'ucp-slider' ); ?></button>
			<button type="button" class="button ucp_remove_brand_image_button" style="<?php echo $image_url ? '' : 'display:none;'; ?>"><?php _e( 'إزالة الصورة', 'ucp-slider' ); ?></button>
		</td>
	</tr>
	<?php
}
add_action( 'product_brand_edit_form_fields', 'ucp_edit_brand_custom_fields', 10 );

/**
 * حفظ بيانات الماركات
 */
function ucp_save_brand_custom_fields( $term_id ) {
	update_term_meta( $term_id, 'ucp_show_brand_in_app', isset( $_POST['ucp_show_brand_in_app'] ) ? '1' : '0' );
	update_term_meta( $term_id, 'ucp_show_brand_in_slider', isset( $_POST['ucp_show_brand_in_slider'] ) ? '1' : '0' );
	if ( isset( $_POST['ucp_brand_slider_image_id'] ) ) {
		update_term_meta( $term_id, 'ucp_brand_slider_image_id', sanitize_text_field( $_POST['ucp_brand_slider_image_id'] ) );
	}
}
add_action( 'created_product_brand', 'ucp_save_brand_custom_fields', 10 );
add_action( 'edited_product_brand', 'ucp_save_brand_custom_fields', 10 );

/**
 * تحميل مكتبة الوسائط والسكربتات اللازمة
 */
function ucp_admin_assets( $hook ) {
    $screen = get_current_screen();
    if ( !in_array($screen->id, ['edit-product_cat', 'edit-product_brand', 'term-product_brand']) ) {
        return;
    }
	wp_enqueue_media();
}
add_action( 'admin_enqueue_scripts', 'ucp_admin_assets' );

/**
 * حقن السكربت في ذيل الصفحة
 */
function ucp_admin_footer_scripts() {
    $screen = get_current_screen();
    if ( !in_array($screen->id, ['edit-product_cat', 'edit-product_brand', 'term-product_brand']) ) {
        return;
    }
	?>
	<script>
	jQuery(document).ready(function($){
		var frame;
		
		// رفع صورة السلايدر للفئات
		$(document).on('click', '.ucp_upload_image_button', function(e){
			e.preventDefault();
			if ( frame ) { frame.open(); return; }
			frame = wp.media({
				title: '<?php echo esc_js( __("اختر صورة السلايدر", "ucp-slider") ); ?>',
				button: { text: '<?php echo esc_js( __("استخدام هذه الصورة", "ucp-slider") ); ?>' },
				multiple: false
			});
			frame.on('select', function() {
				var attachment = frame.state().get('selection').first().toJSON();
				$('#ucp_slider_image_id').val(attachment.id);
				$('#ucp_slider_image_preview').html('<img src="'+attachment.url+'" style="max-width:300px; display:block;">');
				$('.ucp_remove_image_button').show();
			});
			frame.open();
		});
		
		// إزالة صورة السلايدر للفئات
		$(document).on('click', '.ucp_remove_image_button', function(e){
			e.preventDefault();
			$('#ucp_slider_image_id').val('');
			$('#ucp_slider_image_preview').empty();
			$(this).hide();
		});
		
		// رفع صورة السلايدر للماركات
		$(document).on('click', '.ucp_upload_brand_image_button', function(e){
			e.preventDefault();
			if ( frame ) { frame.open(); return; }
			frame = wp.media({
				title: '<?php echo esc_js( __("اختر صورة السلايدر للماركة", "ucp-slider") ); ?>',
				button: { text: '<?php echo esc_js( __("استخدام هذه الصورة", "ucp-slider") ); ?>' },
				multiple: false
			});
			frame.on('select', function() {
				var attachment = frame.state().get('selection').first().toJSON();
				$('#ucp_brand_slider_image_id').val(attachment.id);
				$('#ucp_brand_slider_image_preview').html('<img src="'+attachment.url+'" style="max-width:300px; display:block;">');
				$('.ucp_remove_brand_image_button').show();
			});
			frame.open();
		});
		
		// إزالة صورة السلايدر للماركات
		$(document).on('click', '.ucp_remove_brand_image_button', function(e){
			e.preventDefault();
			$('#ucp_brand_slider_image_id').val('');
			$('#ucp_brand_slider_image_preview').empty();
			$(this).hide();
		});
	});
	</script>
	<?php
}
add_action( 'admin_print_footer_scripts', 'ucp_admin_footer_scripts' );

/**
 * إضافة البيانات للـ REST API (الفئات والماركات)
 */
function ucp_register_atrest_fields() {
    // حقول الفئات
	register_rest_field( 'product_cat', 'slider_data', array(
		'get_callback' => function( $term ) {
			$show_in_slider = get_term_meta( $term['id'], 'ucp_show_in_slider', true ) === '1';
			$image_id       = get_term_meta( $term['id'], 'ucp_slider_image_id', true );
			$image_url      = $image_id ? wp_get_attachment_url( $image_id ) : null;
			
			return array(
				'is_featured'  => $show_in_slider,
				'slider_image' => $image_url,
			);
		}
	));

    // حقول الماركات - إعدادات التطبيق
    register_rest_field( 'product_brand', 'app_settings', array(
		'get_callback' => function( $term ) {
			$show_in_app = get_term_meta( $term['id'], 'ucp_show_brand_in_app', true );
			return array(
				'show_in_app' => ($show_in_app === '1'),
			);
		}
	));
	
	// حقول الماركات - بيانات السلايدر
	register_rest_field( 'product_brand', 'slider_data', array(
		'get_callback' => function( $term ) {
			$show_in_slider = get_term_meta( $term['id'], 'ucp_show_brand_in_slider', true ) === '1';
			$image_id       = get_term_meta( $term['id'], 'ucp_brand_slider_image_id', true );
			$image_url      = $image_id ? wp_get_attachment_url( $image_id ) : null;
			
			return array(
				'is_featured'  => $show_in_slider,
				'slider_image' => $image_url,
			);
		}
	));
}
add_action( 'rest_api_init', 'ucp_register_atrest_fields' );
/**
 * إضافة إعدادات FCM للوحة التحكم
 */
function ucp_add_fcm_settings_menu() {
    add_options_page(
        'إعدادات الإشعارات (FCM v1)',
        'إعدادات FCM',
        'manage_options',
        'ucp-fcm-settings',
        'ucp_fcm_settings_page_html'
    );
}
add_action('admin_menu', 'ucp_add_fcm_settings_menu');

function ucp_fcm_settings_page_html() {
    ?>
    <div class="wrap">
        <h1>إعدادات إشعارات التطبيق (FCM HTTP v1)</h1>
        <p>استخدم هذه الصفحة لضبط إعدادات إشعارات Firebase الحديثة.</p>
        <form method="post" action="options.php">
            <?php
            settings_fields('ucp_fcm_settings_group');
            do_settings_sections('ucp-fcm-settings');
            submit_button();
            ?>
        </form>
    </div>
    <?php
}

function ucp_register_fcm_settings() {
    register_setting('ucp_fcm_settings_group', 'ucp_fcm_service_account_json');
    
    add_settings_section(
        'ucp_fcm_main_section',
        'الإعدادات الأساسية (HTTP v1)',
        null,
        'ucp-fcm-settings'
    );

    add_settings_field(
        'ucp_fcm_service_account_json',
        'Service Account JSON',
        'ucp_fcm_service_account_json_html',
        'ucp-fcm-settings',
        'ucp_fcm_main_section'
    );
}
add_action('admin_init', 'ucp_register_fcm_settings');

function ucp_fcm_service_account_json_html() {
    $value = get_option('ucp_fcm_service_account_json');
    echo '<textarea name="ucp_fcm_service_account_json" rows="10" cols="50" class="large-text" placeholder=\'أقفل هنا محتوى ملف الـ JSON الخاص بـ Service Account...\'>' . esc_textarea($value) . '</textarea>';
    echo '<p class="description">يمكنك الحصول على هذا الملف من: Firebase Console > Project Settings > Service Accounts > Generate New Private Key.</p>';
}

/**
 * دالة لتوليد Access Token لـ FCM v1
 */
function ucp_get_fcm_access_token() {
    $json_content = get_option('ucp_fcm_service_account_json');
    if (!$json_content) return false;

    $service_account = json_decode($json_content, true);
    if (!$service_account) return false;

    $now = time();
    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'iss'   => $service_account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'exp'   => $now + 3600,
        'iat'   => $now
    ]);

    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));

    $signature = '';
    openssl_sign($base64UrlHeader . "." . $base64UrlPayload, $signature, $service_account['private_key'], OPENSSL_ALGO_SHA256);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

    $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;

    $response = wp_remote_post('https://oauth2.googleapis.com/token', [
        'body' => [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt
        ]
    ]);

    if (is_wp_error($response)) return false;

    $data = json_decode(wp_remote_retrieve_body($response), true);
    return isset($data['access_token']) ? $data['access_token'] : false;
}

/**
 * تسجيل نقطة اتصال API مخصصة لتحديث توكن الإشعارات
 */
function ucp_register_fcm_api_routes() {
    // لتحديث التوكن (POST)
    register_rest_route('ucp/v1', '/update-fcm-token', [
        'methods'             => 'POST',
        'callback'            => 'ucp_handle_fcm_token_update',
        'permission_callback' => '__return_true',
    ]);
    
    // للتجربة (GET) للتأكد أن الرابط يعمل
    register_rest_route('ucp/v1', '/test-reachability', [
        'methods'             => 'GET',
        'callback'            => function() { return ['status' => 'ok', 'message' => 'UCP API is reachable']; },
        'permission_callback' => '__return_true',
    ]);
}
add_action('rest_api_init', 'ucp_register_fcm_api_routes');

function ucp_handle_fcm_token_update($request) {
    $params  = $request->get_json_params(); // محاولة جلب البيانات من Body JSON
    $user_id = isset($params['user_id']) ? $params['user_id'] : $request->get_param('user_id');
    $token   = isset($params['fcm_token']) ? $params['fcm_token'] : $request->get_param('fcm_token');

    if (!$user_id || !$token) {
        return new WP_Error('missing_params', 'Missing user_id or fcm_token', ['status' => 400]);
    }

    update_user_meta($user_id, '_fcm_token', $token);
    
    error_log("UCP FCM: Token updated for User #$user_id via Custom API");
    
    return [
        'success' => true,
        'message' => 'Token updated successfully',
        'user_id' => $user_id
    ];
}

/**
 * إرسال إشعار عند تغيير حالة الطلب (FCM v1)
 */
function ucp_send_order_status_notification($order_id, $from_status, $to_status, $order) {
    error_log("UCP FCM: Order status changed for Order #{$order_id} from {$from_status} to {$to_status}");
    
    $customer_id = $order->get_customer_id();
    if (!$customer_id) {
        error_log("UCP FCM: No customer ID found for Order #{$order_id}");
        return;
    }

    $fcm_token = get_user_meta($customer_id, '_fcm_token', true);
    if (!$fcm_token) {
        error_log("UCP FCM: No FCM token found for Customer #{$customer_id}");
        return;
    }

    $access_token = ucp_get_fcm_access_token();
    if (!$access_token) {
        error_log("UCP FCM: Failed to get Google Access Token. Check your Service Account JSON.");
        return;
    }

    $json_content = get_option('ucp_fcm_service_account_json');
    $service_account = json_decode($json_content, true);
    $project_id = isset($service_account['project_id']) ? $service_account['project_id'] : '';

    if (!$project_id) {
        error_log("UCP FCM: Project ID missing from Service Account JSON");
        return;
    }

    $status_names = [
        'pending'    => 'قيد الانتظار',
        'processing' => 'قيد التنفيذ',
        'on-hold'    => 'قيد التوقف المؤقت',
        'completed'  => 'مكتمل',
        'cancelled'  => 'ملغي',
        'refunded'   => 'مسترجع',
        'failed'     => 'فشل',
    ];

    $new_status_name = isset($status_names[$to_status]) ? $status_names[$to_status] : $to_status;
    
    $title = "تحديث حالة الطلب";
    $body = "حالة طلبك رقم #{$order_id} تغيرت إلى: {$new_status_name}";

    $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";
    
    $message = [
        'message' => [
            'token' => $fcm_token,
            'notification' => [
                'title' => $title,
                'body'  => $body,
            ],
            'data' => [
                'order_id' => (string)$order_id,
                'status'   => $to_status,
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'sound' => 'default',
                ]
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                    ]
                ]
            ]
        ]
    ];

    $response = wp_remote_post($url, [
        'headers' => [
            'Authorization' => 'Bearer ' . $access_token,
            'Content-Type'  => 'application/json',
        ],
        'body' => json_encode($message),
        'timeout' => 15
    ]);
    
    if (is_wp_error($response)) {
        error_log("UCP FCM Error: " . $response->get_error_message());
    } else {
        error_log("UCP FCM Response for Order #{$order_id}: " . wp_remote_retrieve_body($response));
    }
}
add_action('woocommerce_order_status_changed', 'ucp_send_order_status_notification', 10, 4);
