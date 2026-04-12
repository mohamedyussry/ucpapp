<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_DeepLink {
    public function __construct() {
        add_action( 'init', [ $this, 'handle_direct_deeplink' ] );
        add_action( 'wp_head', [ $this, 'add_auto_redirect_script' ] );
        add_action( 'wp_footer', [ $this, 'add_fallback_button' ] );
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

    /**
     * يحقن سكريبت التحويل التلقائي للتطبيق في رأس الصفحة (Head) للمنتجات
     */
    public function add_auto_redirect_script() {
        if ( function_exists('is_product') && is_product() ) {
            global $post;
            if ( ! $post ) return;
            
            $slug = $post->post_name;
            $app_link = "ucpapp://product/" . esc_js($slug);
            ?>
            <!-- UCP App Auto-Redirect & Smart Link -->
            <script type="text/javascript">
              (function() {
                var userAgent = navigator.userAgent || navigator.vendor || window.opera;
                var isMobile = /android/i.test(userAgent) || /iPad|iPhone|iPod/.test(userAgent);
                
                if (isMobile) {
                    var appLink = "<?php echo $app_link; ?>";
                    
                    // محاولة التحويل التلقائي فوراً
                    window.location.href = appLink;
                    
                    // إذا لم يفتح التطبيق خلال ثانية، نظهر زر يدوي (Fallback)
                    setTimeout(function() {
                        var banner = document.getElementById('ucp-app-banner');
                        if (banner) banner.style.display = 'block';
                    }, 1500);
                }
              })();
            </script>
            <style>
                #ucp-app-banner {
                    display: none;
                    position: fixed;
                    top: 0; left: 0; width: 100%;
                    background: #f89406; color: white;
                    padding: 15px; text-align: center;
                    z-index: 9999; font-family: sans-serif;
                    box-shadow: 0 2px 5px rgba(0,0,0,0.2);
                }
                #ucp-app-banner a {
                    color: white; font-weight: bold; text-decoration: underline;
                    margin-left: 10px; border: 1px solid white; padding: 5px 10px;
                    border-radius: 5px;
                }
            </style>
            <?php
        }
    }

    /**
     * يضيف زر "الفتح في التطبيق" كحل احتياطي في أسفل الصفحة
     */
    public function add_fallback_button() {
        if ( function_exists('is_product') && is_product() ) {
            global $post;
            if ( ! $post ) return;
            $slug = $post->post_name;
            $app_link = "ucpapp://product/" . esc_attr($slug);
            ?>
            <div id="ucp-app-banner">
                <span><?php _e('تصفح هذا المنتج في تطبيقنا لتجربة أفضل', 'ucp-app-core'); ?></span>
                <a href="<?php echo $app_link; ?>"><?php _e('فتح في التطبيق', 'ucp-app-core'); ?></a>
            </div>
            <?php
        }
    }
}
