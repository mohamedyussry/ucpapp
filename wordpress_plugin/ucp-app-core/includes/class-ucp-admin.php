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
        add_options_page( 'إعدادات FCM', 'إعدادات FCM', 'manage_options', 'ucp-fcm', [ $this, 'fcm_page' ] );
        add_options_page( 'تحديثات التطبيق', 'تحديثات التطبيق', 'manage_options', 'ucp-updates', [ $this, 'updates_page' ] );
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

    public function enqueue_assets($hook) {
        if ( ! in_array( $hook, [ 'post.php', 'post-new.php', 'edit-tags.php', 'term.php' ] ) ) return;
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
                    btn.prev().val(attachment.id);
                    btn.parent().find('.preview').html('<img src="'+attachment.url+'" style="max-width:200px;display:block;">');
                });
                frame.open();
            });
        });
        </script>
        <?php
    }
}
