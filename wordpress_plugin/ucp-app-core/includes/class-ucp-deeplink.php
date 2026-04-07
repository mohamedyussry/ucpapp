<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_DeepLink {
    public function __construct() {
        add_action( 'init', [ $this, 'register_rewrite_rules' ] );
        add_filter( 'query_vars', [ $this, 'add_query_vars' ] );
        add_action( 'template_redirect', [ $this, 'handle_deeplink_files' ] );
    }

    public function register_rewrite_rules() {
        add_rewrite_rule( '^\.well-known/assetlinks\.json$', 'index.php?ucp_deeplink=android', 'top' );
        add_rewrite_rule( '^\.well-known/apple-app-site-association$', 'index.php?ucp_deeplink=ios', 'top' );
        
        // Ensure the rules are flushed if needed (only once)
        // flush_rewrite_rules(); 
    }

    public function add_query_vars( $vars ) {
        $vars[] = 'ucp_deeplink';
        return $vars;
    }

    public function handle_deeplink_files() {
        $type = get_query_var( 'ucp_deeplink' );
        if ( ! $type ) return;

        if ( $type === 'android' ) {
            $this->serve_android_json();
        } elseif ( $type === 'ios' ) {
            $this->serve_ios_json();
        }
        exit;
    }

    private function serve_android_json() {
        header( 'Content-Type: application/json' );
        echo json_encode([
            [
                "relation" => ["delegate_permission/common.handle_all_urls"],
                "target" => [
                    "namespace" => "android_app",
                    "package_name" => "khp.ucpksa.com",
                    "sha256_cert_fingerprints" => [
                        "e0:18:db:1f:bb:d7:2b:21:b6:cf:d7:f9:4e:5c:fe:e6:46:09:22:42:1c:a6:9d:7b:54:c7:c7:02:e9:0b:2a:b8"
                    ]
                ]
            ]
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }

    private function serve_ios_json() {
        header( 'Content-Type: application/json' );
        echo json_encode([
            "applinks" => [
                "apps" => [],
                "details" => [
                    [
                        "appID" => "868TM9X9TU.khp.ucpksa.com",
                        "paths" => [ "/product/*", "/shop/*", "/product-category/*" ]
                    ]
                ]
            ]
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }
}
