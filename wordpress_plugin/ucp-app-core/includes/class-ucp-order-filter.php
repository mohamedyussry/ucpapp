<?php
if ( ! defined( 'ABSPATH' ) ) exit;

/**
 * UCP_Order_Filter
 * Adds a "Source" (Mobile App vs Website) filter and column to WooCommerce Orders admin page.
 */
class UCP_Order_Filter {

    public function __construct() {
        // Add filter dropdown above orders table
        add_action( 'restrict_manage_posts', [ $this, 'add_source_filter_dropdown' ] );
        add_action( 'woocommerce_order_list_table_restrict_manage_orders', [ $this, 'add_source_filter_dropdown_hpos' ] );

        // Apply the filter to the query
        add_filter( 'request', [ $this, 'filter_orders_by_source' ] );
        add_filter( 'woocommerce_order_query_args', [ $this, 'filter_orders_query_hpos' ] );

        // Add "Source" column to orders table
        add_filter( 'manage_woocommerce_page_wc-orders_columns', [ $this, 'add_source_column' ] );
        add_filter( 'manage_shop_order_posts_columns', [ $this, 'add_source_column' ] );

        // Populate the "Source" column
        add_action( 'manage_woocommerce_page_wc-orders_custom_column', [ $this, 'render_source_column' ], 10, 2 );
        add_action( 'manage_shop_order_posts_custom_column', [ $this, 'render_source_column_legacy' ], 10, 2 );

        // Enqueue inline styles for the badges
        add_action( 'admin_head', [ $this, 'add_badge_styles' ] );
    }

    /**
     * Add the filter dropdown (HPOS mode)
     */
    public function add_source_filter_dropdown_hpos( $order_type ) {
        $this->render_filter_dropdown();
    }

    /**
     * Add the filter dropdown (Legacy posts mode)
     */
    public function add_source_filter_dropdown( $post_type ) {
        if ( $post_type !== 'shop_order' ) return;
        $this->render_filter_dropdown();
    }

    /**
     * Renders the HTML dropdown UI
     */
    private function render_filter_dropdown() {
        $current = isset( $_GET['_order_source_filter'] ) ? sanitize_text_field( $_GET['_order_source_filter'] ) : '';
        ?>
        <select name="_order_source_filter" id="ucp_order_source_filter">
            <option value=""><?php esc_html_e( '📦 كل المصادر', 'ucp-app-core' ); ?></option>
            <option value="mobile_app"  <?php selected( $current, 'mobile_app' ); ?>><?php esc_html_e( '📱 تطبيق الجوال', 'ucp-app-core' ); ?></option>
            <option value="web" <?php selected( $current, 'web' ); ?>><?php esc_html_e( '🌐 الموقع الإلكتروني', 'ucp-app-core' ); ?></option>
        </select>
        <?php
    }

    /**
     * Filter orders query (Legacy posts mode)
     */
    public function filter_orders_by_source( $vars ) {
        global $pagenow, $typenow;

        if ( $pagenow !== 'edit.php' || $typenow !== 'shop_order' ) return $vars;
        if ( empty( $_GET['_order_source_filter'] ) ) return $vars;

        $source = sanitize_text_field( $_GET['_order_source_filter'] );

        if ( $source === 'mobile_app' ) {
            $vars['meta_query'][] = [
                'key'     => '_order_source',
                'value'   => 'mobile_app',
                'compare' => '=',
            ];
        } elseif ( $source === 'web' ) {
            $vars['meta_query'][] = [
                'relation' => 'OR',
                [
                    'key'     => '_order_source',
                    'compare' => 'NOT EXISTS',
                ],
                [
                    'key'     => '_order_source',
                    'value'   => 'mobile_app',
                    'compare' => '!=',
                ],
            ];
        }

        return $vars;
    }

    /**
     * Filter orders query (HPOS mode)
     */
    public function filter_orders_query_hpos( $args ) {
        if ( empty( $_GET['_order_source_filter'] ) ) return $args;

        $source = sanitize_text_field( $_GET['_order_source_filter'] );

        if ( $source === 'mobile_app' ) {
            $args['meta_query'][] = [
                'key'     => '_order_source',
                'value'   => 'mobile_app',
                'compare' => '=',
            ];
        } elseif ( $source === 'web' ) {
            $args['meta_query'][] = [
                'relation' => 'OR',
                [
                    'key'     => '_order_source',
                    'compare' => 'NOT EXISTS',
                ],
                [
                    'key'     => '_order_source',
                    'value'   => 'mobile_app',
                    'compare' => '!=',
                ],
            ];
        }

        return $args;
    }

    /**
     * Add "Source" column header to orders table
     */
    public function add_source_column( $columns ) {
        // Insert after 'order_status' column
        $new_columns = [];
        foreach ( $columns as $key => $value ) {
            $new_columns[ $key ] = $value;
            if ( $key === 'order_status' ) {
                $new_columns['ucp_order_source'] = __( 'المصدر', 'ucp-app-core' );
            }
        }
        return $new_columns;
    }

    /**
     * Render the source column (HPOS mode)
     */
    public function render_source_column( $column_name, $order ) {
        if ( $column_name !== 'ucp_order_source' ) return;
        $source = $order->get_meta( '_order_source' );
        $this->render_source_badge( $source );
    }

    /**
     * Render the source column (Legacy posts mode)
     */
    public function render_source_column_legacy( $column, $post_id ) {
        if ( $column !== 'ucp_order_source' ) return;
        $order = wc_get_order( $post_id );
        if ( ! $order ) return;
        $source = $order->get_meta( '_order_source' );
        $this->render_source_badge( $source );
    }

    /**
     * Renders the HTML badge
     */
    private function render_source_badge( $source ) {
        if ( $source === 'mobile_app' ) {
            echo '<span class="ucp-source-badge ucp-source-mobile">📱 تطبيق</span>';
        } else {
            echo '<span class="ucp-source-badge ucp-source-web">🌐 موقع</span>';
        }
    }

    /**
     * Add inline CSS styles for the badges
     */
    public function add_badge_styles() {
        $screen = get_current_screen();
        if ( ! $screen ) return;
        // Only on WooCommerce orders pages
        if ( $screen->id !== 'edit-shop_order' && $screen->id !== 'woocommerce_page_wc-orders' ) return;
        ?>
        <style>
            .ucp-source-badge {
                display: inline-block;
                padding: 3px 10px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 600;
                white-space: nowrap;
            }
            .ucp-source-mobile {
                background-color: #fff3e0;
                color: #e65100;
                border: 1px solid #ffb74d;
            }
            .ucp-source-web {
                background-color: #e8f5e9;
                color: #2e7d32;
                border: 1px solid #81c784;
            }
        </style>
        <?php
    }
}
