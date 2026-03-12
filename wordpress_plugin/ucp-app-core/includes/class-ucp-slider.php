<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_Slider {
    public function __construct() {
        // Hooks for Category
        add_action( 'product_cat_add_form_fields', [ $this, 'cat_fields_add' ] );
        add_action( 'product_cat_edit_form_fields', [ $this, 'cat_fields_edit' ] );
        add_action( 'created_product_cat', [ $this, 'save_term_meta' ] );
        add_action( 'edited_product_cat', [ $this, 'save_term_meta' ] );

        // Hooks for Brand
        add_action( 'product_brand_add_form_fields', [ $this, 'brand_fields_add' ] );
        add_action( 'product_brand_edit_form_fields', [ $this, 'brand_fields_edit' ] );
        add_action( 'created_product_brand', [ $this, 'save_brand_meta' ] );
        add_action( 'edited_product_brand', [ $this, 'save_brand_meta' ] );

        // Hooks for Product
        add_action( 'add_meta_boxes', [ $this, 'product_metabox' ] );
        add_action( 'woocommerce_process_product_meta', [ $this, 'save_product_meta' ] );
        add_action( 'save_post_product', [ $this, 'save_product_meta' ] );
    }

    // ============================================
    // الفئات Categories
    // ============================================
    public function cat_fields_add() { $this->cat_fields_html(); }
    public function cat_fields_edit($term) { $this->cat_fields_html($term); }

    private function cat_fields_html($term = null) {
        $img_id = $term ? get_term_meta($term->term_id, 'ucp_slider_image_id', true) : '';
        $img_url = $img_id ? wp_get_attachment_url($img_id) : '';
        $featured = $term ? get_term_meta($term->term_id, 'ucp_show_in_slider', true) : '0';
        ?>
        <div class="form-field">
            <label>إظهار في سلايدر التطبيق</label>
            <input type="checkbox" name="ucp_show_in_slider" value="1" <?php checked($featured, '1'); ?>>
        </div>
        <div class="form-field">
            <label>صورة السلايدر (أبعاد 16:9)</label>
            <input type="hidden" name="ucp_slider_image_id" value="<?php echo esc_attr($img_id); ?>">
            <div class="preview" style="margin-bottom:10px;">
                <?php if($img_url) echo "<img src='$img_url' style='max-width:200px;'>"; ?>
            </div>
            <button class="button ucp_upload_button">رفع/اختيار صورة</button>
        </div>
        <?php
    }

    public function save_term_meta($term_id) {
        update_term_meta($term_id, 'ucp_show_in_slider', isset($_POST['ucp_show_in_slider']) ? '1' : '0');
        if(isset($_POST['ucp_slider_image_id'])) {
            update_term_meta($term_id, 'ucp_slider_image_id', sanitize_text_field($_POST['ucp_slider_image_id']));
        }
    }

    // ============================================
    // الماركات Brands
    // ============================================
    public function brand_fields_add() { $this->brand_fields_html(); }
    public function brand_fields_edit($term) { $this->brand_fields_html($term); }

    private function brand_fields_html($term = null) {
        $img_id = $term ? get_term_meta($term->term_id, 'ucp_brand_slider_image_id', true) : '';
        $img_url = $img_id ? wp_get_attachment_url($img_id) : '';
        $featured_slider = $term ? get_term_meta($term->term_id, 'ucp_show_brand_in_slider', true) : '0';
        
        $show_in_app = $term ? get_term_meta($term->term_id, 'ucp_show_brand_in_app', true) : '0';
        if ($term && $show_in_app === '') $show_in_app = '0'; // default value
        ?>
        <div class="form-field">
            <label>إظهار في التطبيق</label>
            <input type="checkbox" name="ucp_show_brand_in_app" value="1" <?php checked($show_in_app, '1'); ?>>
            <p class="description">تحكم في ظهور هذه الماركة في الصفحة الرئيسية لتطبيقك.</p>
        </div>
        <div class="form-field">
            <label>إظهار في سلايدر التطبيق</label>
            <input type="checkbox" name="ucp_show_brand_in_slider" value="1" <?php checked($featured_slider, '1'); ?>>
        </div>
        <div class="form-field">
            <label>صورة السلايدر للماركة (أبعاد 16:9)</label>
            <input type="hidden" name="ucp_brand_slider_image_id" value="<?php echo esc_attr($img_id); ?>">
            <div class="preview" style="margin-bottom:10px;">
                <?php if($img_url) echo "<img src='$img_url' style='max-width:200px;'>"; ?>
            </div>
            <button class="button ucp_upload_button">رفع/اختيار صورة</button>
        </div>
        <?php
    }

    public function save_brand_meta($term_id) {
        update_term_meta($term_id, 'ucp_show_brand_in_app', isset($_POST['ucp_show_brand_in_app']) ? '1' : '0');
        update_term_meta($term_id, 'ucp_show_brand_in_slider', isset($_POST['ucp_show_brand_in_slider']) ? '1' : '0');
        if(isset($_POST['ucp_brand_slider_image_id'])) {
            update_term_meta($term_id, 'ucp_brand_slider_image_id', sanitize_text_field($_POST['ucp_brand_slider_image_id']));
        }
    }

    // ============================================
    // المنتجات Products
    // ============================================
    public function product_metabox() {
        add_meta_box( 
            'ucp_product_slider_metabox', 
            'إعدادات السلايدر (للتطبيق)', 
            [ $this, 'product_metabox_html' ], 
            'product', 
            'side', 
            'high' 
        );
    }

    public function product_metabox_html($post) {
        wp_nonce_field( 'ucp_product_slider_save', 'ucp_product_slider_nonce' );
        $show_in_slider = get_post_meta( $post->ID, 'ucp_show_product_in_slider', true );
        $image_id       = get_post_meta( $post->ID, 'ucp_product_slider_image_id', true );
        $image_url      = $image_id ? wp_get_attachment_url( $image_id ) : '';
        ?>
        <div style="padding:6px 0;">
            <p style="margin:0 0 10px;">
                <label style="display:flex;align-items:center;gap:8px;font-weight:600;cursor:pointer;">
                    <input type="checkbox" name="ucp_show_product_in_slider" value="1" <?php checked( $show_in_slider, '1' ); ?>>
                    إظهار المنتج في السلايدر العلوي للتطبيق
                </label>
            </p>
            <div style="margin-top:10px;">
                <strong style="display:block;margin-bottom:6px;">صورة السلايدر المخصصة (أبعاد 16:9)</strong>
                <input type="hidden" name="ucp_product_slider_image_id" value="<?php echo esc_attr( $image_id ); ?>">
                <div class="preview" style="margin-bottom:6px;">
                    <?php if ( $image_url ) : ?>
                        <img src="<?php echo esc_url( $image_url ); ?>" style="max-width:100%; display:block; border-radius:6px;">
                    <?php endif; ?>
                </div>
                <button type="button" class="button button-primary ucp_upload_button" style="margin-top:4px;">📂 رفع/اختيار صورة</button>
            </div>
        </div>
        <?php
    }

    public function save_product_meta($post_id) {
        if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) return;
        if ( ! current_user_can( 'edit_post', $post_id ) ) return;

        $show_in_slider = isset( $_POST['ucp_show_product_in_slider'] ) ? '1' : '0';
        update_post_meta( $post_id, 'ucp_show_product_in_slider', $show_in_slider );

        if ( array_key_exists( 'ucp_product_slider_image_id', $_POST ) ) {
            update_post_meta( $post_id, 'ucp_product_slider_image_id', sanitize_text_field( $_POST['ucp_product_slider_image_id'] ) );
        }
    }

    // ============================================
    // تجميع البيانات للـ API
    // ============================================
    public function collect_all_items() {
        $items = [];
        
        // 1. Categories
        $cats = get_terms([
            'taxonomy' => 'product_cat', 
            'hide_empty' => false, 
            'meta_query' => [['key' => 'ucp_show_in_slider', 'value' => '1', 'compare' => '=']]
        ]);
        if(!is_wp_error($cats)) {
            foreach($cats as $c) {
                $img_id = get_term_meta($c->term_id, 'ucp_slider_image_id', true);
                $items[] = [ 'type' => 'category', 'id' => $c->term_id, 'name' => $c->name, 'image' => $img_id ? wp_get_attachment_url($img_id) : '' ];
            }
        }

        // 2. Brands
        $brands = get_terms([
            'taxonomy' => 'product_brand', 
            'hide_empty' => false, 
            'meta_query' => [['key' => 'ucp_show_brand_in_slider', 'value' => '1', 'compare' => '=']]
        ]);
        if(!is_wp_error($brands)) {
            foreach($brands as $b) {
                $img_id = get_term_meta($b->term_id, 'ucp_brand_slider_image_id', true);
                $items[] = [ 'type' => 'brand', 'id' => $b->term_id, 'name' => $b->name, 'image' => $img_id ? wp_get_attachment_url($img_id) : '' ];
            }
        }

        // 3. Products
        $prods = get_posts([
            'post_type' => 'product', 
            'posts_per_page' => -1, 
            'meta_query' => [['key' => 'ucp_show_product_in_slider', 'value' => '1', 'compare' => '=']]
        ]);
        foreach($prods as $p) {
            $img_id = get_post_meta($p->ID, 'ucp_product_slider_image_id', true);
            $items[] = [ 'type' => 'product', 'id' => $p->ID, 'name' => $p->post_title, 'image' => $img_id ? wp_get_attachment_url($img_id) : '' ];
        }

        return $items;
    }
}
