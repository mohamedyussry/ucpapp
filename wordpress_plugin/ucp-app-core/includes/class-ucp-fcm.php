<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_FCM {
    public function __construct() {
        add_action( 'woocommerce_order_status_changed', [ $this, 'notify_status_change' ], 10, 4 );
    }

    public function notify_status_change( $order_id, $from, $to, $order ) {
        $customer_id = $order->get_customer_id();
        $token = get_user_meta($customer_id, '_fcm_token', true);
        if (!$token) return;

        $access_token = $this->get_google_token();
        if (!$access_token) return;

        $json = json_decode(get_option('ucp_fcm_service_account_json'), true);
        $project_id = $json['project_id'] ?? '';
        if (!$project_id) return;

        $labels = get_option('ucp_fcm_status_labels', []);
        $status_text = $labels[$to] ?? $to;

        $url = "https://fcm.googleapis.com/v1/projects/$project_id/messages:send";
        $body = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => 'تحديث الطلب',
                    'body' => "حالة طلبك #$order_id تغيرت إلى: $status_text"
                ],
                'data' => [ 'order_id' => (string)$order_id ],
                'android' => [ 'priority' => 'high', 'notification' => [ 'click_action' => 'FLUTTER_NOTIFICATION_CLICK' ] ]
            ]
        ];

        wp_remote_post($url, [
            'headers' => [ 'Authorization' => 'Bearer ' . $access_token, 'Content-Type' => 'application/json' ],
            'body' => json_encode($body)
        ]);
    }

    private function get_google_token() {
        $json = json_decode(get_option('ucp_fcm_service_account_json'), true);
        if (!$json) return false;

        $now = time();
        $header = base64url_encode(json_encode(['alg'=>'RS256','typ'=>'JWT']));
        $payload = base64url_encode(json_encode([
            'iss' => $json['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'exp' => $now + 3600,
            'iat' => $now
        ]));

        openssl_sign("$header.$payload", $sig, $json['private_key'], OPENSSL_ALGO_SHA256);
        $jwt = "$header.$payload." . base64url_encode($sig);

        $res = wp_remote_post('https://oauth2.googleapis.com/token', [
            'body' => [ 'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt ]
        ]);

        $data = json_decode(wp_remote_retrieve_body($res), true);
        return $data['access_token'] ?? false;
    }
}

function base64url_encode($data) {
    return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
}
