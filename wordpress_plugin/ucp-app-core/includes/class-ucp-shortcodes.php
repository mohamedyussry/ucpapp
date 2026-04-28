<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class UCP_Shortcodes {
    public function __construct() {
        add_shortcode( 'ucp_plans', [ $this, 'render_subscription_plans' ] );
        add_action( 'wp_enqueue_scripts', [ $this, 'enqueue_styles' ] );
        add_action( 'template_redirect', [ $this, 'handle_form_submission' ] );
        
        // WooCommerce Hooks لحفظ بيانات المريض مع الطلب
        add_filter( 'woocommerce_add_cart_item_data', [ $this, 'add_patient_data_to_cart' ], 10, 2 );
        add_filter( 'woocommerce_get_item_data', [ $this, 'display_patient_data_in_cart' ], 10, 2 );
        add_action( 'woocommerce_checkout_create_order_line_item', [ $this, 'add_patient_data_to_order' ], 10, 4 );
    }

    public function enqueue_styles() {
        wp_register_style( 'ucp-plans-style', false );
        wp_enqueue_style( 'ucp-plans-style' );
        wp_add_inline_style( 'ucp-plans-style', $this->get_custom_css() );
    }

    public function handle_form_submission() {
        if ( isset($_POST['ucp_subscribe_nonce']) && wp_verify_nonce($_POST['ucp_subscribe_nonce'], 'ucp_subscribe_action') ) {
            // التحقق من أن التسجيل متاح حالياً
            if ( get_option('ucp_subscription_allow_new', '1') !== '1' ) {
                wc_add_notice( 'نعتذر، التسجيل في الاشتراكات موقوف حالياً.', 'error' );
                return;
            }

            // التحقق من تسجيل الدخول
            if ( ! is_user_logged_in() ) {
                wc_add_notice( 'يجب تسجيل الدخول لتتمكن من الاشتراك في الباقات.', 'error' );
                return;
            }
            
            $product_id = intval($_POST['selected_plan']);
            if ( ! $product_id ) {
                wc_add_notice( 'يرجى اختيار باقة.', 'error' );
                return;
            }

            // تجميع بيانات المريض بشكل آمن لتجنب أي أخطاء PHP
            $patient_data = [
                'full_name' => isset($_POST['patient_name']) ? sanitize_text_field($_POST['patient_name']) : '',
                'dob'       => isset($_POST['patient_dob']) ? sanitize_text_field($_POST['patient_dob']) : '',
                'id_number' => isset($_POST['patient_id']) ? sanitize_text_field($_POST['patient_id']) : '',
                'gender'    => isset($_POST['patient_gender']) ? sanitize_text_field($_POST['patient_gender']) : '',
                'weight'    => isset($_POST['patient_weight']) ? sanitize_text_field($_POST['patient_weight']) : '',
                'height'    => isset($_POST['patient_height']) ? sanitize_text_field($_POST['patient_height']) : '',
                'mobile'    => isset($_POST['patient_mobile']) ? sanitize_text_field($_POST['patient_mobile']) : '',
                'city'      => isset($_POST['patient_city']) ? sanitize_text_field($_POST['patient_city']) : '',
                'email'     => isset($_POST['patient_email']) ? sanitize_email($_POST['patient_email']) : '',
            ];

            // تفريغ السلة لضمان اشتراك واحد في كل مرة
            if ( WC()->cart ) {
                WC()->cart->empty_cart();
            }

            // إضافة المنتج للسلة مع البيانات المخصصة
            $cart_item_data = [ 'ucp_patient_data' => $patient_data ];
            WC()->cart->add_to_cart( $product_id, 1, 0, [], $cart_item_data );

            // إعادة توجيه لصفحة الدفع
            wp_safe_redirect( wc_get_checkout_url() );
            exit;
        }
    }

    public function add_patient_data_to_cart( $cart_item_data, $product_id ) {
        // لم نعد بحاجة لهذا الفلتر لأننا نمرر البيانات مباشرة، ولكن نتركه لعدم كسر كود قديم إن وجد
        return $cart_item_data;
    }

    public function display_patient_data_in_cart( $item_data, $cart_item ) {
        if ( empty( $cart_item['ucp_patient_data'] ) ) return $item_data;
        
        $item_data[] = [
            'key'     => 'الاسم',
            'value'   => $cart_item['ucp_patient_data']['full_name'],
        ];
        $item_data[] = [
            'key'     => 'رقم الهوية',
            'value'   => $cart_item['ucp_patient_data']['id_number'],
        ];
        return $item_data;
    }

    public function add_patient_data_to_order( $item, $cart_item_key, $values, $order ) {
        if ( empty( $values['ucp_patient_data'] ) ) return;

        $data = $values['ucp_patient_data'];
        $item->add_meta_data( 'اسم المريض', $data['full_name'] );
        $item->add_meta_data( 'تاريخ الميلاد', $data['dob'] );
        $item->add_meta_data( 'رقم الهوية', $data['id_number'] );
        $item->add_meta_data( 'النوع', $data['gender'] );
        $item->add_meta_data( 'الوزن', $data['weight'] );
        $item->add_meta_data( 'الطول', $data['height'] );
        $item->add_meta_data( 'الجوال', $data['mobile'] );
        $item->add_meta_data( 'المدينة', $data['city'] );
        $item->add_meta_data( 'البريد', $data['email'] );
    }

    public function render_subscription_plans() {
        // التحقق من تسجيل الدخول أولاً
        if ( ! is_user_logged_in() ) {
            $login_url = wc_get_page_permalink('myaccount');
            return '<div style="text-align:center; padding:50px 20px; background:#f8fafc; border-radius:15px; border:1px solid #e2e8f0; margin:20px 0; direction:rtl;">
                        <span class="dashicons dashicons-lock" style="font-size:48px; width:48px; height:48px; color:#94a3b8; margin-bottom:15px; display:inline-block;"></span>
                        <h3 style="color:#0f172a; font-weight:800; font-size:22px; margin:0 0 10px 0;">مطلوب تسجيل الدخول</h3>
                        <p style="color:#64748b; font-size:16px; margin:0 0 25px 0;">يجب أن تكون مسجلاً للدخول في حسابك لتتمكن من استعراض الباقات والاشتراك بها.</p>
                        <a href="'.esc_url($login_url).'" style="display:inline-block; background:#f97316; color:#fff; padding:12px 30px; border-radius:10px; text-decoration:none; font-weight:800; font-size:16px; transition:all 0.3s ease;">تسجيل الدخول / إنشاء حساب</a>
                    </div>';
        }

        // التحقق من أن التسجيل متاح حالياً
        if ( get_option('ucp_subscription_allow_new', '1') !== '1' ) {
            return '<div style="text-align:center; padding:50px; background:#f9f9f9; border-radius:10px; border:1px solid #ddd;">
                        <span class="dashicons dashicons-lock" style="font-size:50px; width:50px; height:50px; color:#666; margin-bottom:20px;"></span>
                        <h3>عذراً، التسجيل موقوف حالياً</h3>
                        <p>تم إيقاف استقبال مشتركين جدد في الوقت الحالي، نعتذر عن أي إزعاج ونرجو المحاولة لاحقاً.</p>
                    </div>';
        }

        $plans = get_option('ucp_subscription_plans', []);
        
        ob_start();
        ?>
        <div class="ucp-stepper-wrapper">
            <form method="post" id="ucp-subscription-form">
                <?php wp_nonce_field('ucp_subscribe_action', 'ucp_subscribe_nonce'); ?>

                <!-- Progress Bar -->
                <div class="ucp-progress">
                    <div class="step active" id="step-nav-1">1. اختيار الباقة</div>
                    <div class="step" id="step-nav-2">2. المعلومات الشخصية</div>
                    <div class="step" id="step-nav-3">3. الموافقة</div>
                </div>

                <!-- Step 1: Plans -->
                <div class="ucp-step-content active" id="step-content-1">
                    <h2>اختر الباقة التي تناسب أهدافك ووقتك</h2>
                    <div class="selection-list">
                        <?php if(empty($plans)): ?>
                            <p>لا توجد باقات متاحة حالياً.</p>
                        <?php else: ?>
                            <?php foreach ($plans as $index => $plan): ?>
                                <div class="selection-item">
                                    <label class="selection-label">
                                        <input type="radio" name="selected_plan" value="<?php echo esc_attr($plan['product_id']); ?>" <?php echo $index === 0 ? 'checked' : ''; ?>>
                                        <div class="selection-content">
                                            <div class="selection-header">
                                                <h3><?php echo esc_html($plan['name_ar']); ?></h3>
                                            </div>
                                            <ul class="selection-features">
                                                <?php if (!empty($plan['features'])): ?>
                                                    <?php foreach ($plan['features'] as $feature): ?>
                                                        <li>- <?php echo esc_html($feature); ?></li>
                                                    <?php endforeach; ?>
                                                <?php endif; ?>
                                            </ul>
                                            <div class="selection-price">
                                                السعر: <span><?php echo esc_html($plan['price']); ?> ر.س</span> (يشمل التوصيل)
                                            </div>
                                        </div>
                                    </label>
                                </div>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </div>
                    <div class="form-actions">
                        <button type="button" class="btn-next" onclick="ucpNextStep(2)">التالي</button>
                    </div>
                </div>

                <!-- Step 2: Patient Info -->
                <div class="ucp-step-content" id="step-content-2" style="display:none;">
                    <div class="ucp-form-header">
                        <h2 class="form-main-title">أسئلة تسجيل المريض</h2>
                        <p class="form-subtitle">دعنا نتعرف عليك أكثر! أجب عن بعض الأسئلة السريعة لكي نتمكن من إعداد خطة مناسبة لك وتتناسب مع أهدافك، نمط حياتك، واحتياجاتك الصحية.</p>
                    </div>

                    <div class="ucp-section-header">القسم أ: المعلومات الشخصية</div>
                    
                    <div class="ucp-form-grid">
                        <div class="form-group">
                            <label>الاسم الكامل:</label>
                            <input type="text" name="patient_name" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group">
                            <label>تاريخ الميلاد:</label>
                            <input type="date" name="patient_dob" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group">
                            <label>رقم الهوية:</label>
                            <input type="text" name="patient_id" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group">
                            <label>النوع:</label>
                            <select name="patient_gender" required class="ucp-input">
                                <option value="" disabled selected>*</option>
                                <option value="ذكر">ذكر</option>
                                <option value="أنثى">أنثى</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>الوزن الحالي (كغ):</label>
                            <input type="number" name="patient_weight" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group">
                            <label>الطول الحالي (سم):</label>
                            <input type="number" name="patient_height" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group">
                            <label>رقم الجوال:</label>
                            <input type="tel" name="patient_mobile" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group">
                            <label>مدينة الإقامة:</label>
                            <input type="text" name="patient_city" placeholder="*" required class="ucp-input">
                        </div>
                        <div class="form-group full-width">
                            <label>البريد الإلكتروني:</label>
                            <input type="email" name="patient_email" placeholder="*" required class="ucp-input">
                        </div>
                    </div>
                    
                    <div class="form-actions left-align">
                        <button type="button" class="btn-next large-btn" onclick="if(ucpValidateStep2()) ucpNextStep(3);">التالي</button>
                    </div>
                </div>

                <!-- Step 3: Consent -->
                <div class="ucp-step-content" id="step-content-3" style="display:none;">
                    <h2>موافقة</h2>
                    <div class="consent-box">
                        <ul>
                            <li>أقر أنني أوافق على ما سيتم توضيحه لي بشأن طبيعة الاستشارة الطبية عن بعد والعلاج أو التوصيات المقترحة.</li>
                            <li>كما أفهم أن خدمة الطب الاتصالي قد تتم عبر الهاتف أو الاتصال المرئي، وأن المعلومات المتاحة قد تكون أقل من الفحص الحضوري.</li>
                            <li>وبموجب هذا أوافق على تلقي الاستشارة والعلاج عبر الطب الاتصالي.</li>
                            <li>في حال أظهرت النتائج المخبرية أو التقييم الطبي عدم اللياقة لأخذ علاج (منجارو)، سوف يتم استرجاع قيمة العلاج فقط.</li>
                            <li>يحق للعميل استرداد المبلغ كاملاً في حال ثبت عدم ملاءمته طبياً للبرنامج.</li>
                            <li>لا يمكن استرجاع الأدوية التي تتطلب سلسلة تبريد بعد استلامها.</li>
                            <li>في حال رغبة العميل بإلغاء ما تبقى من الاشتراك، يتم احتساب رسوم الفحوصات وسحب العينات.</li>
                        </ul>
                        
                        <div class="consent-checkbox">
                            <label>
                                <input type="checkbox" id="ucp-agree-checkbox" required>
                                <strong>أقر بالموافقة على جميع الشروط والأحكام المذكورة أعلاه.</strong>
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-actions">
                        <button type="button" class="btn-prev" onclick="ucpNextStep(2)">السابق</button>
                        <button type="submit" class="btn-submit" id="btn-submit-form" disabled>الذهاب للدفع</button>
                    </div>
                </div>
            </form>
        </div>

        <script>
            window.ucpNextStep = function(step) {
                var contents = document.querySelectorAll('.ucp-step-content');
                if(contents) contents.forEach(function(el) { el.style.display = 'none'; });
                var steps = document.querySelectorAll('.ucp-progress .step');
                if(steps) steps.forEach(function(el) { el.classList.remove('active'); });
                var stepContent = document.getElementById('step-content-' + step);
                if(stepContent) stepContent.style.display = 'block';
                for(var i=1; i<=step; i++) {
                    var nav = document.getElementById('step-nav-' + i);
                    if(nav) nav.classList.add('active');
                }
                var wrapper = document.querySelector('.ucp-stepper-wrapper');
                if(wrapper) {
                    var topPos = wrapper.getBoundingClientRect().top + window.scrollY - 50;
                    window.scrollTo({top: topPos, behavior: 'smooth'});
                }
            };
            window.ucpValidateStep2 = function() {
                var inputs = document.getElementById('step-content-2').querySelectorAll('input[required], select[required]');
                for(var i=0; i<inputs.length; i++) {
                    if(!inputs[i].value) {
                        if(typeof inputs[i].reportValidity === 'function') {
                            inputs[i].reportValidity();
                        } else {
                            alert('يرجى تعبئة الحقول المطلوبة.');
                        }
                        return false;
                    }
                }
                return true;
            };
            document.addEventListener('DOMContentLoaded', function() {
                var checkbox = document.getElementById('ucp-agree-checkbox');
                if(checkbox) {
                    checkbox.addEventListener('change', function() {
                        var btn = document.getElementById('btn-submit-form');
                        if(btn) btn.disabled = !this.checked;
                    });
                }
            });
        </script>
        <?php
        return ob_get_clean();
    }

    private function get_custom_css() {
        return "
            .ucp-stepper-wrapper {
                direction: rtl !important;
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif !important;
                color: #333 !important;
                max-width: 900px;
                margin: 40px auto;
                background: #fff;
                padding: 40px;
                border-radius: 20px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.05);
            }
            .ucp-stepper-wrapper * { box-sizing: border-box; }
            
            .ucp-progress {
                display: flex;
                justify-content: space-between;
                margin-bottom: 40px;
                border-bottom: 2px solid #eee;
                padding-bottom: 20px;
            }
            .ucp-progress .step {
                flex: 1;
                text-align: center;
                font-weight: bold;
                color: #aaa;
                position: relative;
            }
            .ucp-progress .step.active {
                color: #f29200;
            }
            .ucp-progress .step.active::after {
                content: '';
                position: absolute;
                bottom: -22px;
                left: 0;
                width: 100%;
                height: 3px;
                background: #f29200;
            }

            .ucp-step-content h2 {
                color: #f29200;
                margin-bottom: 20px;
                font-size: 24px;
            }

            /* Step 1 */
            .selection-list { 
                display: grid !important; 
                grid-template-columns: repeat(3, 1fr) !important; 
                gap: 20px !important; 
                margin-bottom: 30px !important; 
            }
            .selection-item { border: 2px solid #eee; border-radius: 10px; padding: 20px; transition: 0.3s; display: flex; flex-direction: column; }
            .selection-item:hover, .selection-item:has(input:checked) { border-color: #f29200; background: #fffaf0; }
            .selection-label { display: flex; align-items: flex-start; gap: 15px; cursor: pointer; width: 100%; margin: 0; }
            .selection-content { flex: 1; }
            .selection-header h3 { margin: 0 0 10px 0; font-size: 18px; color: #333; line-height: 1.4; }
            .selection-features { list-style: none; padding: 0; margin: 0 0 15px 0; color: #666; font-size: 14px; min-height: 80px; }
            .selection-features li { padding-bottom: 5px; }
            .selection-price { font-weight: bold; font-size: 16px; margin-top: auto; border-top: 1px solid #eee; padding-top: 15px; }
            .selection-price span { color: #f29200; font-size: 22px; display: block; margin-top: 5px; }
            input[type='radio'] { width: 20px; height: 20px; accent-color: #f29200; margin-top: 2px; flex-shrink: 0; }

            /* Step 2 specific styles */
            .ucp-form-header { text-align: center; margin-bottom: 40px; }
            .form-main-title { font-size: 32px !important; color: #333; margin-bottom: 15px !important; font-weight: bold; }
            .form-subtitle { font-size: 18px !important; color: #555; line-height: 1.6; max-width: 800px; margin: 0 auto !important; }
            
            .ucp-section-header {
                background-color: #fff4e6 !important;
                border: 1px solid #fce4c4 !important;
                color: #333 !important;
                padding: 15px 25px !important;
                font-size: 20px !important;
                font-weight: bold !important;
                border-radius: 8px !important;
                margin-bottom: 30px !important;
            }

            .ucp-form-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 20px 40px;
                margin-top: 30px;
            }
            .form-group { display: flex; flex-direction: column; }
            .form-group.full-width { grid-column: 1 / -1; }
            .form-group label { margin-bottom: 10px; font-weight: bold; color: #333; font-size: 16px; }
            .ucp-input {
                padding: 15px !important;
                border: 1px solid #ddd !important;
                border-radius: 8px !important;
                font-family: inherit !important;
                font-size: 16px !important;
                transition: 0.3s !important;
                background: #fff !important;
            }
            .ucp-input::placeholder { color: red !important; opacity: 1 !important; }
            .ucp-input:focus {
                border-color: #f29200 !important;
                outline: none !important;
                box-shadow: 0 0 0 3px rgba(242, 146, 0, 0.1) !important;
            }

            /* Step 3 */
            .consent-box ul {
                background: #f9f9f9;
                padding: 20px 40px;
                border-radius: 10px;
                border: 1px solid #eee;
                line-height: 1.8;
                color: #555;
            }
            .consent-box li { margin-bottom: 10px; }
            .consent-checkbox {
                margin-top: 30px;
                background: #fffaf0;
                padding: 20px;
                border-radius: 8px;
                border: 1px dashed #f29200;
            }
            .consent-checkbox label { display: flex; align-items: center; gap: 10px; cursor: pointer; color: #333; }
            .consent-checkbox input { width: 20px; height: 20px; accent-color: #f29200; }

            /* Actions */
            .form-actions {
                display: flex;
                justify-content: flex-end;
                gap: 15px;
                margin-top: 40px;
                border-top: 1px solid #eee;
                padding-top: 20px;
            }
            .form-actions.left-align { justify-content: flex-end; } /* RTL flex-end is left */
            
            .btn-next, .btn-submit {
                background: #f29200 !important;
                color: #fff !important;
                border: none !important;
                padding: 12px 30px !important;
                border-radius: 8px !important;
                font-size: 16px !important;
                font-weight: bold !important;
                cursor: pointer !important;
                transition: 0.3s !important;
            }
            .large-btn { padding: 15px 50px !important; font-size: 18px !important; }
            .btn-prev {
                background: #eee !important;
                color: #555 !important;
                border: none !important;
                padding: 12px 30px !important;
                border-radius: 8px !important;
                font-size: 16px !important;
                font-weight: bold !important;
                cursor: pointer !important;
                transition: 0.3s !important;
            }
            .btn-next:hover, .btn-submit:not(:disabled):hover { background: #d98200 !important; }
            .btn-prev:hover { background: #e0e0e0 !important; }
            .btn-submit:disabled { background: #ccc !important; cursor: not-allowed !important; }

            @media (max-width: 768px) {
                .selection-list { grid-template-columns: 1fr !important; }
                .ucp-form-grid { grid-template-columns: 1fr; }
                .ucp-progress { flex-direction: column; gap: 10px; border: none; }
                .ucp-progress .step.active::after { display: none; }
            }
        ";
    }
}
