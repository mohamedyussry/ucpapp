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
	?>
	<tr class="form-field term-app-show-wrap">
		<th scope="row"><label for="ucp_show_brand_in_app"><?php _e( 'إظهار في التطبيق', 'ucp-slider' ); ?></label></th>
		<td>
			<input type="checkbox" name="ucp_show_brand_in_app" id="ucp_show_brand_in_app" value="1" <?php checked( $show_in_app, '1' ); ?>>
			<p class="description"><?php _e( 'تحكم في ظهور هذه الماركة في الصفحة الرئيسية للتطبيق.', 'ucp-slider' ); ?></p>
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
		$(document).on('click', '.ucp_remove_image_button', function(e){
			e.preventDefault();
			$('#ucp_slider_image_id').val('');
			$('#ucp_slider_image_preview').empty();
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

    // حقول الماركات
    register_rest_field( 'product_brand', 'app_settings', array(
		'get_callback' => function( $term ) {
			$show_in_app = get_term_meta( $term['id'], 'ucp_show_brand_in_app', true );
			return array(
				'show_in_app' => ($show_in_app === '1'),
			);
		}
	));
}
add_action( 'rest_api_init', 'ucp_register_atrest_fields' );
