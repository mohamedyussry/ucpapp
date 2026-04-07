<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_DeepLink {
    public function __construct() {
        add_action( 'init', [ $this, 'handle_direct_deeplink' ] );
    }

    public function handle_direct_deeplink() {
        $uri = $_SERVER['REQUEST_URI'] ?? '';
        
        if ( strpos( $uri, '.well-known/assetlinks.json' ) !== false ) {
            $this->serve_android_json();
            exit;
        }
        
        if ( strpos( $uri, '.well-known/apple-app-site-association' ) !== false ) {
            $this->serve_ios_json();
            exit;
        }
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
                        "paths" => [ 
                            "/product/*", "/shop/*", "/product-category/*", 
                            "/en/shop/*", "/ar/shop/*", 
                            "/en/product/*", "/ar/product/*", 
                            "/en/product-category/*", "/ar/product-category/*",
                            "/*/shop/*", "/*/product/*" 
                        ]
                    ]
                ]
            ]
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }
}
