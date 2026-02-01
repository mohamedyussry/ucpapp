<?php
/**
 * Plugin Name: UCP WooCommerce Slider Integration
 * Plugin URI: https://ucpksa.com
 * Description: إضافة خيارات مخصصة لتصنيفات WooCommerce للتحكم في سلايدر تطبيق Flutter (إظهار في السلايدر + صورة مخصصة للسلايدر).
 * Version: 1.0.0
 * Author: UCP Team
 * Text Domain: ucp-slider
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
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
 * إضافة السكربت الخاص بمكتبة الوسائط في لوحة التحكم
 */
function ucp_admin_enqueue_scripts( $hook ) {
	if ( 'edit-tags.php' !== $hook && 'term.php' !== $hook ) {
		return;
	}
	wp_enqueue_media();
	?>
	<script>
	jQuery(document).ready(function($){
		var frame;
		$('.ucp_upload_image_button').on('click', function(e){
			e.preventDefault();
			if ( frame ) { frame.open(); return; }
			frame = wp.media({
				title: '<?php _e( "اختر صورة السلايدر", "ucp-slider" ); ?>',
				button: { text: '<?php _e( "استخدام هذه الصورة", "ucp-slider" ); ?>' },
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
		$('.ucp_remove_image_button').on('click', function(e){
			e.preventDefault();
			$('#ucp_slider_image_id').val('');
			$('#ucp_slider_image_preview').empty();
			$(this).hide();
		});
	});
	</script>
	<?php
}
add_action( 'admin_enqueue_scripts', 'ucp_admin_enqueue_scripts' );

/**
 * إضافة البيانات للـ REST API
 */
function ucp_register_atrest_slider_fields() {
	register_rest_field( 'product_cat', 'slider_data', array(
		'get_callback' => function( $term ) {
			$show_in_slider = get_term_meta( $term['id'], 'ucp_show_in_slider', true ) === '1';
			$image_id       = get_term_meta( $term['id'], 'ucp_slider_image_id', true );
			$image_url      = $image_id ? wp_get_attachment_url( $image_id ) : null;
			
			return array(
				'is_featured'  => $show_in_slider,
				'slider_image' => $image_url,
			);
		},
		'update_callback' => null,
		'schema'          => null,
	) );
}
add_action( 'rest_api_init', 'ucp_register_atrest_slider_fields' );
