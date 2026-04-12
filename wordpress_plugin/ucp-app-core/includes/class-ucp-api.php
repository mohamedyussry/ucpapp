<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_API {
    public function __construct() {
        add_action( 'rest_api_init', [ $this, 'register_routes' ] );
    }

    public function register_routes() {
        $ns = 'ucp/v1';

        register_rest_route($ns, '/slider-items', [ 'methods' => 'GET', 'callback' => [ $this, 'get_slider_items' ], 'permission_callback' => '__return_true' ]);
        register_rest_route($ns, '/update-info', [ 'methods' => 'GET', 'callback' => [ $this, 'get_update_info' ], 'permission_callback' => '__return_true' ]);
        register_rest_route($ns, '/update-fcm-token', [ 'methods' => 'POST', 'callback' => [ $this, 'update_fcm_token' ], 'permission_callback' => '__return_true' ]);

        register_rest_route($ns, '/product-offers/(?P<id>\d+)', [ 'methods' => 'GET', 'callback' => [ $this, 'get_product_offers' ], 'permission_callback' => '__return_true' ]);

        // تسجيل حقول إضافية لمعرفة الماركات المسموح ظهورها في التطبيق
        register_rest_field( 'product_brand', 'app_settings', [
            'get_callback' => function( $term ) {
                $show_in_app = get_term_meta( $term['id'], 'ucp_show_brand_in_app', true );
                return [ 'show_in_app' => ($show_in_app === '1') ];
            }
        ]);
    }

    public function get_slider_items() {
        $items = [];
        // Implementation of collecting categories, brands, products...
        $slider_logic = new UCP_Slider();
        return $slider_logic->collect_all_items();
    }

    public function get_update_info() {
        return [
            // Update Settings
            'required_version'   => get_option('ucp_required_version', '1.0.0'),
            'is_force_update'    => get_option('ucp_is_force_update') === '1',
            'update_url_android' => get_option('ucp_update_url_android'),
            'update_url_ios'     => get_option('ucp_update_url_ios'),
            'update_message_ar'  => get_option('ucp_update_message_ar'),
            'update_message_en'  => get_option('ucp_update_message_en'),
            
            // Cart Offers Settings
            'free_shipping_enabled'    => get_option('ucp_free_shipping_enabled') === '1',
            'free_shipping_min_amount' => (float) get_option('ucp_free_shipping_min_amount', '250'),
            'free_shipping_msg_ar'     => get_option('ucp_free_shipping_msg_ar', 'أضف منتجات بقيمة [amount] ر.س إضافية للحصول على شحن مجاني!'),
            'free_shipping_msg_en'     => get_option('ucp_free_shipping_msg_en', 'Add [amount] SAR more to get free shipping!'),
            'free_shipping_success_ar' => get_option('ucp_free_shipping_success_ar', 'مبروك! لقد تأهلت للحصول على شحن مجاني! 🚀'),
            'free_shipping_success_en' => get_option('ucp_free_shipping_success_en', 'Congratulations! You qualified for free shipping! 🚀'),

            // Promotion Settings (Marquee)
            'marquee_enabled'    => get_option('ucp_marquee_enabled') === '1',
            'marquee_text_ar'    => get_option('ucp_marquee_text_ar'),
            'marquee_text_en'    => get_option('ucp_marquee_text_en'),
            'marquee_bg_color'   => get_option('ucp_marquee_bg_color', '#ff9800'),
            'marquee_text_color' => get_option('ucp_marquee_text_color', '#ffffff'),
            'marquee_target_type' => get_option('ucp_marquee_target_type', 'external'),
            'marquee_target_id'   => get_option('ucp_marquee_target_id'),

            // Promotion Settings (Popup)
            'popup_enabled'      => get_option('ucp_popup_enabled') === '1',
            'popup_image_url'    => (get_option('ucp_popup_image_id')) ? wp_get_attachment_url(get_option('ucp_popup_image_id')) : '',
            'popup_link'         => get_option('ucp_popup_link'),
            'popup_target_type'  => get_option('ucp_popup_target_type', 'external'),
            'popup_target_id'    => get_option('ucp_popup_target_id'),
        ];
    }

    public function update_fcm_token($request) {
        $params = $request->get_json_params();
        $user_id = $params['user_id'] ?? $request->get_param('user_id');
        $token = $params['fcm_token'] ?? $request->get_param('fcm_token');

        if (!$user_id || !$token) return new WP_Error('error', 'Missing data', ['status'=>400]);

        update_user_meta($user_id, '_fcm_token', $token);
        return ['success' => true];
    }

    public function get_product_offers($request) {
        $product_id = $request['id'];
        $lang = $request->get_param('lang');
        $offers = [];

        if (class_exists('ADP\BaseVersion\Includes\Database\Repository\RuleRepository')) {
            try {
                $repo = new ADP\BaseVersion\Includes\Database\Repository\RuleRepository();
                // We need to pass some arguments to simulate the product environment
                $args = [
                    'product' => (int)$product_id,
                    'active_only' => true
                ];
                
                $rules = $repo->getRules($args);

                foreach ($rules as $rule) {
                    // Try to get a user-friendly label
                    $label = '';
                    
                    if (!empty($rule->advertising) && isset($rule->advertising['badge_text']) && !empty($rule->advertising['badge_text'])) {
                        $label = $rule->advertising['badge_text'];
                    } elseif (!empty($rule->title)) {
                        $label = $rule->title;
                    }

                    if (!empty($label)) {
                        if (!empty($lang)) {
                            // Apply the TranslatePress filter directly. 
                            // WordPress safely ignores this if TranslatePress is not active.
                            $trp_lang = (strtolower($lang) === 'en') ? 'en_US' : 'ar'; 
                            $translated_label = apply_filters('trp_translate', $label, $trp_lang, false);
                            
                            // If not translated and we asked for Arabic, try 'ar_SA' just in case
                            if ($translated_label === $label && strtolower($lang) !== 'en') {
                                $translated_label = apply_filters('trp_translate', $label, 'ar_SA', false);
                            }
                            
                            if (!empty($translated_label) && is_string($translated_label)) {
                                $label = $translated_label;
                            }
                        }

                        // Remove SKU details like (SKU 12345) from the label
                        $label = preg_replace('/\s*\(SKU\s+.*?\)/i', '', $label);
                        $label = trim($label);

                        $offers[] = $label;
                    }
                }
            } catch (Exception $e) {
                // Silently fail or log if needed
            }
        }

        return array_unique($offers);
    }
}
