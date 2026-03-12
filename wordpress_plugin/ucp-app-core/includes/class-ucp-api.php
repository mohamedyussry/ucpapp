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
    }

    public function get_slider_items() {
        $items = [];
        // Implementation of collecting categories, brands, products...
        $slider_logic = new UCP_Slider();
        return $slider_logic->collect_all_items();
    }

    public function get_update_info() {
        return [
            'required_version'   => get_option('ucp_required_version', '1.0.0'),
            'is_force_update'    => get_option('ucp_is_force_update') === '1',
            'update_url_android' => get_option('ucp_update_url_android'),
            'update_url_ios'     => get_option('ucp_update_url_ios'),
            'update_message_ar'  => get_option('ucp_update_message_ar'),
            'update_message_en'  => get_option('ucp_update_message_en')
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
}
