<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_Banner {
    public function __construct() {
        add_action( 'wp_head', [ $this, 'add_smart_banner_meta' ] );
        add_action( 'wp_footer', [ $this, 'render_smart_banner_ui' ] );
    }

    public function add_smart_banner_meta() {
        echo '<meta name="apple-itunes-app" content="app-id=6758623777, app-argument=' . esc_url( $this->get_current_page_app_link() ) . '">';
    }

    public function render_smart_banner_ui() {
        if ( ! wp_is_mobile() ) return;

        $store_link_android = "https://play.google.com/store/apps/details?id=khp.ucpksa.com";
        $store_link_ios = "https://apps.apple.com/app/id6758623777"; 
        ?>
        <style>
            #ucp-smart-banner {
                position: fixed; top: 0; left: 0; width: 100%; height: 75px;
                background: #ffffff; border-bottom: 1px solid #eee;
                display: flex; align-items: center; justify-content: space-between;
                padding: 0 15px; z-index: 999999; box-shadow: 0 2px 5px rgba(0,0,0,0.1);
                font-family: sans-serif;
            }
            #ucp-smart-banner .info { display: flex; align-items: center; flex: 1; }
            #ucp-smart-banner .icon {
                width: 50px; height: 50px; background: #FF9800; border-radius: 10px;
                margin-right: 12px; display: flex; align-items: center; justify-content: center;
                color: white; font-weight: bold; font-size: 20px; overflow: hidden;
            }
            #ucp-smart-banner .title { font-weight: bold; font-size: 14px; color: #333; margin-bottom: 2px; }
            #ucp-smart-banner .subtitle { font-size: 12px; color: #666; }
            #ucp-smart-banner .actions { display: flex; align-items: center; }
            #ucp-smart-banner .btn-open {
                background: #FF9800; color: white; padding: 8px 16px;
                border-radius: 20px; font-weight: bold; text-decoration: none; font-size: 13px;
                transition: background 0.2s;
            }
            #ucp-smart-banner .btn-close {
                padding: 5px; color: #999; text-decoration: none; font-size: 18px; margin-right: 5px;
            }
            body { margin-top: 75px !important; }
        </style>

        <div id="ucp-smart-banner">
            <div class="info">
                <a href="javascript:void(0)" class="btn-close" onclick="closeUcpBanner()">×</a>
                <div class="icon">UCP</div>
                <div>
                    <div class="title">صيدلية UCP - التطبيق الرسمي</div>
                    <div class="subtitle">تجربة أفضل للتسوق عبر الجوال</div>
                </div>
            </div>
            <div class="actions">
                <a href="#" class="btn-open" id="ucp-open-btn">فتح</a>
            </div>
        </div>
        
        <script>
            document.getElementById('ucp-open-btn').addEventListener('click', function(e) {
                e.preventDefault();
                var startTime = new Date().getTime();
                var isAndroid = /Android/i.test(navigator.userAgent);
                var isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);
                
                var pathSegments = window.location.pathname.split('/').filter(function(s) { return s.length > 0; });
                var slug = "";
                if (pathSegments.indexOf('product') !== -1) {
                    slug = pathSegments[pathSegments.indexOf('product') + 1];
                } else if (pathSegments.indexOf('shop') !== -1) {
                    slug = pathSegments[pathSegments.indexOf('shop') + 1];
                }

                var customScheme = "ucpapp://" + (slug || "");
                var storeUrl = isAndroid ? "<?php echo $store_link_android; ?>" : "<?php echo $store_link_ios; ?>";

                // 1. Try to open the app directly
                window.location.href = customScheme;

                // 2. Fallback to Store
                setTimeout(function() {
                    if (new Date().getTime() - startTime < 3000) {
                        window.location.href = storeUrl;
                    }
                }, 2500);
            });

            function closeUcpBanner() {
                document.getElementById('ucp-smart-banner').style.display = 'none';
                document.body.style.marginTop = '0px';
            }
        </script>
        <?php
    }

    private function get_current_page_app_link() {
        return 'https://ucpksa.com' . $_SERVER['REQUEST_URI'];
    }
}
