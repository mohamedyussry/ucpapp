<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_Admin {
    public function __construct() {
        add_action( 'admin_menu', [ $this, 'add_menus' ] );
        add_action( 'admin_init', [ $this, 'register_settings' ] );
        add_action( 'admin_enqueue_scripts', [ $this, 'enqueue_assets' ] );
        add_action( 'admin_print_footer_scripts', [ $this, 'render_js' ] );
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

    public function enqueue_assets($hook) {
        if ( ! in_array( $hook, [ 'post.php', 'post-new.php', 'edit-tags.php', 'term.php', 'settings_page_ucp-promotions' ] ) ) return;
        wp_enqueue_media();
    }

    public function render_js() {
        ?>
        <script>
        jQuery(document).ready(function($){
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
        });
        </script>
        <?php
    }
}
