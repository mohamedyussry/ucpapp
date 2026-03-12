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
    }

    public function cat_fields_add() { $this->render_term_fields(); }
    public function cat_fields_edit($term) { $this->render_term_fields($term); }

    private function render_term_fields($term = null) {
        $img_id = $term ? get_term_meta($term->term_id, 'ucp_slider_image_id', true) : '';
        $img_url = $img_id ? wp_get_attachment_url($img_id) : '';
        $featured = $term ? get_term_meta($term->term_id, 'ucp_show_in_slider', true) : '0';
        ?>
        <div class="form-field">
            <label>إظهار في السلايدر</label>
            <input type="checkbox" name="ucp_show_in_slider" value="1" <?php checked($featured, '1'); ?>>
        </div>
        <div class="form-field">
            <label>صورة السلايدر (16:9)</label>
            <input type="hidden" name="ucp_slider_image_id" value="<?php echo esc_attr($img_id); ?>">
            <div class="preview"><?php if($img_url) echo "<img src='$img_url' style='max-width:200px;'>"; ?></div>
            <button class="button ucp_upload_button">رفع صورة</button>
        </div>
        <?php
    }

    // Similar logic for Brands and Products...
    // To keep it short for this example, I'll implement the collector used by API
    public function collect_all_items() {
        $items = [];
        
        // Categories
        $cats = get_terms(['taxonomy'=>'product_cat', 'meta_key'=>'ucp_show_in_slider', 'meta_value'=>'1']);
        foreach($cats as $c) {
            $items[] = [ 'type'=>'category', 'id'=>$c->term_id, 'name'=>$c->name, 'image'=>wp_get_attachment_url(get_term_meta($c->term_id, 'ucp_slider_image_id', true)) ];
        }

        // Brands
        $brands = get_terms(['taxonomy'=>'product_brand', 'meta_key'=>'ucp_show_brand_in_slider', 'meta_value'=>'1']);
        foreach($brands as $b) {
            $items[] = [ 'type'=>'brand', 'id'=>$b->term_id, 'name'=>$b->name, 'image'=>wp_get_attachment_url(get_term_meta($b->term_id, 'ucp_brand_slider_image_id', true)) ];
        }

        // Products
        $prods = get_posts(['post_type'=>'product', 'meta_key'=>'ucp_show_product_in_slider', 'meta_value'=>'1', 'posts_per_page'=>-1]);
        foreach($prods as $p) {
            $items[] = [ 'type'=>'product', 'id'=>$p->ID, 'name'=>$p->post_title, 'image'=>wp_get_attachment_url(get_post_meta($p->ID, 'ucp_product_slider_image_id', true)) ];
        }

        return $items;
    }

    public function save_term_meta($term_id) {
        update_term_meta($term_id, 'ucp_show_in_slider', isset($_POST['ucp_show_in_slider']) ? '1' : '0');
        if(isset($_POST['ucp_slider_image_id'])) update_term_meta($term_id, 'ucp_slider_image_id', $_POST['ucp_slider_image_id']);
    }

    // Brand and Product save methods omitted for brevity but they follow the same pattern
}
