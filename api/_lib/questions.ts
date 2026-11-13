import type { Question } from './engine';
import { EXTRA_QUESTIONS } from './questions-extra';
import { HARD_QUESTIONS } from './questions-hard';
import { PACK4A } from './questions-pack4a';
import { PACK4B } from './questions-pack4b';
import { PACK4C } from './questions-pack4c';

/**
 * Question bank. Ids must be unique. Everything players see is Arabic with
 * English digits. `decoys` are believable wrong answers used for players who
 * run out of time; `level: 'hard'` questions are used when the host picks "صعب".
 */
const BASE_QUESTIONS: Question[] = [
  // ------------------------------------------------------------------ تاريخ
  { id: 'hh1', level: 'hard', category: 'history', text: 'مين أول خليفة أموي؟', answer: 'معاوية بن أبي سفيان', aliases: ['معاوية'], decoys: ['يزيد بن معاوية', 'مروان بن الحكم', 'عبد الملك بن مروان'] },
  { id: 'hh2', level: 'hard', category: 'history', text: 'مين القائد اللي بنى مدينة القاهرة؟', answer: 'جوهر الصقلي', aliases: ['جوهر'], decoys: ['أحمد بن طولون', 'الحاكم بأمر الله', 'عمرو بن العاص'] },
  { id: 'hh3', level: 'hard', category: 'history', text: 'حرب المئة عام بين إنجلترا وفرنسا استمرت كام سنة فعلاً؟', answer: '116', decoys: ['100', '99', '112'] },
  { id: 'hh4', level: 'hard', category: 'history', text: 'مين آخر ملك حكم مصر؟', answer: 'أحمد فؤاد الثاني', aliases: ['فؤاد الثاني'], decoys: ['فاروق الأول', 'فؤاد الأول', 'عباس حلمي الثاني'] },
  { id: 'hh5', level: 'hard', category: 'history', text: 'حجر رشيد مكتوب بكام خط؟', answer: '3', aliases: ['تلاتة', 'ثلاثة'], decoys: ['2', '4', '5'] },
  { id: 'hh6', level: 'hard', category: 'history', text: 'مين أول رئيس لجمهورية مصر؟', answer: 'محمد نجيب', decoys: ['جمال عبد الناصر', 'أنور السادات', 'عبد الحكيم عامر'] },
  { id: 'hh7', level: 'hard', category: 'history', text: 'معركة عين جالوت كانت ضد مين؟', answer: 'المغول', aliases: ['التتار'], decoys: ['الصليبيين', 'الفرس', 'البيزنطيين'] },
  { id: 'hh8', level: 'hard', category: 'history', text: 'في أي سنة اتأممت قناة السويس؟', answer: '1956', decoys: ['1952', '1967', '1954'] },

  // -------------------------------------------------------------------- أدب
  { id: 'l1', category: 'literature', text: 'مين مؤلف رواية «بين القصرين»؟', answer: 'نجيب محفوظ', aliases: ['محفوظ'], decoys: ['يوسف إدريس', 'إحسان عبد القدوس', 'توفيق الحكيم'] },
  { id: 'l4', category: 'literature', text: 'مين مؤلف رواية «موسم الهجرة إلى الشمال»؟', answer: 'الطيب صالح', decoys: ['عبد الرحمن منيف', 'حنا مينه', 'جبرا إبراهيم جبرا'] },
  { id: 'l6', category: 'literature', text: 'مين مؤلف رواية «دون كيخوته»؟', answer: 'ثيربانتس', aliases: ['سرفانتس', 'سيرفانتس'], decoys: ['لوركا', 'دانتي', 'بوكاتشيو'] },
  { id: 'hl1', level: 'hard', category: 'literature', text: 'مين كتب رواية «عزازيل»؟', answer: 'يوسف زيدان', decoys: ['علاء الأسواني', 'أحمد مراد', 'بهاء طاهر'] },
  { id: 'hl2', level: 'hard', category: 'literature', text: 'مين كتب رواية «رجال في الشمس»؟', answer: 'غسان كنفاني', aliases: ['كنفاني'], decoys: ['محمود درويش', 'إميل حبيبي', 'سميح القاسم'] },
  { id: 'hl3', level: 'hard', category: 'literature', text: 'مين كتب قصيدة «الأطلال» اللي غنتها أم كلثوم؟', answer: 'إبراهيم ناجي', decoys: ['أحمد رامي', 'بيرم التونسي', 'مأمون الشناوي'] },
  { id: 'hl4', level: 'hard', category: 'literature', text: 'مين مؤلف رواية «مئة عام من العزلة»؟', answer: 'غابرييل غارسيا ماركيز', aliases: ['ماركيز', 'جابرييل جارسيا ماركيز'], decoys: ['خورخي لويس بورخيس', 'إيزابيل الليندي', 'ماريو بارغاس يوسا'] },
  { id: 'hl5', level: 'hard', category: 'literature', text: 'نجيب محفوظ أخد جايزة نوبل في الأدب سنة كام؟', answer: '1988', decoys: ['1990', '1985', '1979'] },
  { id: 'hl6', level: 'hard', category: 'literature', text: 'مين الشاعر اللي اتلقب بـ«شاعر النيل»؟', answer: 'حافظ إبراهيم', decoys: ['خليل مطران', 'محمود سامي البارودي', 'أحمد رامي'] },
  { id: 'hl7', level: 'hard', category: 'literature', text: 'مين ترجم كتاب «كليلة ودمنة» للعربي؟', answer: 'ابن المقفع', decoys: ['الجاحظ', 'ابن رشد', 'الفارابي'] },
  { id: 'hl8', level: 'hard', category: 'literature', text: 'مين مؤلف كتاب «المقدمة» الشهير؟', answer: 'ابن خلدون', decoys: ['ابن بطوطة', 'ابن سينا', 'المقريزي'] },

  // -------------------------------------------------------------------- كورة
  { id: 'f3', category: 'football', text: 'مين كسب أول كأس عالم سنة 1930؟', answer: 'أوروجواي', aliases: ['الأوروغواي', 'أوروغواي'], decoys: ['الأرجنتين', 'البرازيل', 'إيطاليا'] },
  { id: 'f4', category: 'football', text: 'أنهي نادي كسب أول نسخة من كأس أوروبا للأندية الأبطال سنة 1956؟', answer: 'ريال مدريد', aliases: ['الريال'], decoys: ['برشلونة', 'ميلان', 'بنفيكا'] },
  { id: 'hf1', level: 'hard', category: 'football', text: 'مين هداف كأس العالم 2014؟', answer: 'خاميس رودريغيز', aliases: ['خاميس', 'جيمس رودريجيز', 'خاميس رودريجيز'], decoys: ['توماس مولر', 'ليونيل ميسي', 'نيمار'] },
  { id: 'hf2', level: 'hard', category: 'football', text: 'النادي الأهلي اتأسس سنة كام؟', answer: '1907', decoys: ['1911', '1905', '1920'] },
  { id: 'hf3', level: 'hard', category: 'football', text: 'نادي الزمالك كان اسمه إيه أول ما اتأسس؟', answer: 'قصر النيل', aliases: ['نادي قصر النيل'], decoys: ['نادي الجزيرة', 'نادي الأمير', 'نادي القاهرة'] },
  { id: 'hf4', level: 'hard', category: 'football', text: 'مين أول منتخب أفريقي يوصل نص نهائي كأس العالم؟', answer: 'المغرب', decoys: ['الكاميرون', 'السنغال', 'غانا'] },
  { id: 'hf5', level: 'hard', category: 'football', text: 'مصر كسبت كأس الأمم الأفريقية كام مرة؟', answer: '7', aliases: ['سبعة', 'سبع مرات', 'سبع'], decoys: ['6', '8', '5'] },
  { id: 'hf6', level: 'hard', category: 'football', text: 'مين المدرب اللي كسب مع مصر 3 بطولات أمم أفريقية ورا بعض؟', answer: 'حسن شحاتة', decoys: ['محمود الجوهري', 'حسام البدري', 'فاروق جعفر'] },
  { id: 'hf8', level: 'hard', category: 'football', text: 'مين هداف كأس العالم 2002؟', answer: 'رونالدو البرازيلي', aliases: ['رونالدو', 'رونالدو نازاريو'], decoys: ['ميروسلاف كلوزه', 'ريفالدو', 'دافور شوكر'] },
  // الدوري السعودي
  { id: 'fs1', category: 'football', text: 'الدوري السعودي انطلق سنة كام؟', answer: '1976', decoys: ['1970', '1980', '1974'] },
  { id: 'fs2', category: 'football', text: 'مين الهداف التاريخي للدوري السعودي؟', answer: 'ماجد عبدالله', aliases: ['ماجد عبد الله', 'ماجد'], decoys: ['سامي الجابر', 'ياسر القحطاني', 'محمد نور'] },
  { id: 'fs3', level: 'hard', category: 'football', text: 'مين أول نادي كسب الدوري السعودي الممتاز؟', answer: 'الهلال', decoys: ['النصر', 'الاتحاد', 'الشباب'] },
  { id: 'fs4', category: 'football', text: 'النصر السعودي كسب الدوري كام مرة لحد موسم 2024-2025؟', answer: '9', aliases: ['تسعة', 'تسع', 'تسع مرات'], decoys: ['7', '11', '12'] },
  { id: 'fs5', category: 'football', text: 'الاتحاد السعودي كسب الدوري كام مرة لحد موسم 2024-2025؟', answer: '10', aliases: ['عشرة', 'عشر', 'عشر مرات'], decoys: ['8', '12', '6'] },
  { id: 'fs6', level: 'hard', category: 'football', text: 'مين اللاعب الوحيد اللي لعب 19 موسم ورا بعض في الدوري السعودي؟', answer: 'محمد الشلهوب', aliases: ['الشلهوب'], decoys: ['ياسر القحطاني', 'سعود كريري', 'حسين عبدالغني'] },
  { id: 'fs7', category: 'football', text: 'الهلال أكتر نادي كسب الدوري السعودي، كسبه كام مرة لحد موسم 2024-2025؟', answer: '19', aliases: ['تسعتاشر', 'تسعة عشر'], decoys: ['15', '17', '21'] },
  { id: 'fs8', category: 'football', text: 'كام فريق بيهبط من الدوري السعودي كل موسم؟', answer: '3', aliases: ['تلاتة', 'ثلاثة'], decoys: ['2', '4', '1'] },
  { id: 'fs9', level: 'hard', category: 'football', text: 'الدوري السعودي فيه كام جولة من موسم 2023-2024؟', answer: '34', decoys: ['30', '38', '32'] },
  { id: 'fs10', level: 'hard', category: 'football', text: 'مين المدافع اللي كسب الدوري السعودي 5 مرات مع الهلال والأهلي؟', answer: 'أسامة هوساوي', aliases: ['هوساوي'], decoys: ['ياسر الشهراني', 'أسامة المولد', 'حسين عبدالغني'] },

  // الدوري المصري
  { id: 'fe1', level: 'hard', category: 'football', text: 'الأهلي كسب الدوري المصري كام مرة لحد موسم 2024-2025؟', answer: '45', decoys: ['41', '43', '47'] },
  { id: 'fe2', category: 'football', text: 'الزمالك كسب الدوري المصري كام مرة لحد موسم 2024-2025؟', answer: '14', aliases: ['أربعتاشر', 'أربعة عشر'], decoys: ['12', '11', '16'] },
  { id: 'fe3', level: 'hard', category: 'football', text: 'مين الهداف التاريخي للدوري المصري؟', answer: 'حسن الشاذلي', aliases: ['الشاذلي'], decoys: ['محمود الخطيب', 'عماد متعب', 'مصطفى رياض'] },
  { id: 'fe4', category: 'football', text: 'الدوري المصري انطلق سنة كام؟', answer: '1948', decoys: ['1923', '1956', '1936'] },
  { id: 'fe5', level: 'hard', category: 'football', text: 'مين صاحب أسرع هدف في تاريخ الدوري المصري؟', answer: 'أيمن يونس', decoys: ['حسام حسن', 'جمال عبد الحميد', 'طارق السعيد'] },
  { id: 'fe6', category: 'football', text: 'مين أول نادي كسب الدوري المصري؟', answer: 'الأهلي', decoys: ['الزمالك', 'الترسانة', 'الإسماعيلي'] },
  { id: 'fe7', category: 'football', text: 'الدوري المصري موسم 2023-2024 كان فيه كام جولة؟', answer: '34', decoys: ['30', '38', '32'] },
  { id: 'fe8', level: 'hard', category: 'football', text: 'الدوري المصري موسم 2023-2024 اتلعب فيه كام ماتش؟', answer: '306', decoys: ['340', '272', '380'] },

  // دوري أبطال آسيا
  { id: 'fa1', level: 'hard', category: 'football', text: 'بطولة آسيا للأندية الأبطال اتلعبت أول مرة سنة كام؟', answer: '1967', decoys: ['1985', '1972', '1960'] },
  { id: 'fa2', category: 'football', text: 'مين أكتر نادي كسب دوري أبطال آسيا؟', answer: 'الهلال', aliases: ['الهلال السعودي'], decoys: ['بوهانج ستيلرز', 'أوراوا ريد دايموندز', 'العين'] },
  { id: 'fa3', category: 'football', text: 'الهلال كسب دوري أبطال آسيا كام مرة لحد 2025؟', answer: '4', aliases: ['أربعة', 'أربع', 'أربع مرات'], decoys: ['3', '5', '6'] },
  { id: 'fa4', level: 'hard', category: 'football', text: 'مين الهداف التاريخي لدوري أبطال آسيا؟', answer: 'لي دونج جوك', aliases: ['لي دونغ غوك', 'لي دونج كوك'], decoys: ['عمر السومة', 'بافيتيمبي جوميز', 'ياسر القحطاني'] },
  { id: 'fa5', category: 'football', text: 'النصر السعودي كسب دوري أبطال آسيا كام مرة؟', answer: '0', aliases: ['ولا مرة', 'صفر'], decoys: ['1', '2', '3'] },
  { id: 'fa6', level: 'hard', category: 'football', text: 'كام نادي عربي كسب دوري أبطال آسيا لحد 2025؟', answer: '5', aliases: ['خمسة', 'خمس'], decoys: ['3', '4', '6'] },
  { id: 'fa7', level: 'hard', category: 'football', text: 'الهلال خسر كام نهائي في دوري أبطال آسيا بنظامها الحالي (من 2002)؟', answer: '3', aliases: ['تلاتة', 'ثلاثة'], decoys: ['2', '4', '5'] },

  // دوري أبطال أفريقيا
  { id: 'fc1', category: 'football', text: 'الأهلي كسب دوري أبطال أفريقيا كام مرة لحد 2025؟', answer: '12', aliases: ['اتناشر', 'اثنا عشر'], decoys: ['10', '9', '14'] },
  { id: 'fc2', category: 'football', text: 'الزمالك كسب دوري أبطال أفريقيا كام مرة؟', answer: '5', aliases: ['خمسة', 'خمس', 'خمس مرات'], decoys: ['3', '4', '7'] },
  { id: 'fc3', level: 'hard', category: 'football', text: 'الترجي التونسي كسب دوري أبطال أفريقيا كام مرة؟', answer: '4', aliases: ['أربعة', 'أربع', 'أربع مرات'], decoys: ['2', '3', '6'] },
  { id: 'fc4', level: 'hard', category: 'football', text: 'مين سجل هدف الأهلي في مرمى الصفاقسي في إياب نهائي دوري أبطال أفريقيا 2006؟', answer: 'محمد أبو تريكة', aliases: ['أبو تريكة', 'تريكة'], decoys: ['عماد متعب', 'محمد بركات', 'فلافيو'] },
  { id: 'fc5', level: 'hard', category: 'football', text: 'الزمالك وصل لنهائي دوري أبطال أفريقيا كام مرة؟', answer: '7', aliases: ['سبعة', 'سبع', 'سبع مرات'], decoys: ['6', '8', '9'] },
  { id: 'fc6', level: 'hard', category: 'football', text: 'مين الهداف التاريخي لدوري أبطال أفريقيا؟', answer: 'تريزور مبوتو', aliases: ['مبوتو', 'تريسور مبوتو'], decoys: ['محمد أبو تريكة', 'عماد متعب', 'فلافيو'] },
  { id: 'fc7', category: 'football', text: 'أنهي دولة أنديتها كسبت دوري أبطال أفريقيا أكتر مرات؟', answer: 'مصر', decoys: ['المغرب', 'تونس', 'الكونغو الديمقراطية'] },
  { id: 'fc8', level: 'hard', category: 'football', text: 'الأهلي والزمالك اتقابلوا في كام ماتش في دوري أبطال أفريقيا لحد 2025؟', answer: '9', aliases: ['تسعة', 'تسع'], decoys: ['6', '12', '11'] },
  { id: 'fc9', level: 'hard', category: 'football', text: 'نهائي دوري أبطال أفريقيا 2020 «نهائي القرن» بين الأهلي والزمالك اتلعب في أنهي استاد؟', answer: 'استاد القاهرة', aliases: ['ستاد القاهرة', 'استاد القاهرة الدولي'], decoys: ['استاد برج العرب', 'استاد محمد الخامس', 'استاد رادس'] },

  // متنوع: الإمارات وكأس العالم
  { id: 'fm1', level: 'hard', category: 'football', text: 'الدوري الإماراتي انطلق سنة كام؟', answer: '1973', decoys: ['1971', '1980', '1975'] },
  { id: 'fm2', level: 'hard', category: 'football', text: 'مين الهداف التاريخي للدوري الإماراتي؟', answer: 'علي مبخوت', aliases: ['مبخوت'], decoys: ['فهد خميس', 'عمر عبدالرحمن', 'إسماعيل مطر'] },
  { id: 'fm3', category: 'football', text: 'مين أكتر نادي كسب الدوري الإماراتي؟', answer: 'العين', decoys: ['الوصل', 'شباب الأهلي', 'الشارقة'] },
  { id: 'fm4', category: 'football', text: 'مين النادي الإماراتي الوحيد اللي كسب دوري أبطال آسيا؟', answer: 'العين', decoys: ['الوحدة', 'الجزيرة', 'شباب الأهلي'] },
  { id: 'fm6', level: 'hard', category: 'football', text: 'قبل مونديال 2026 كأس العالم شهد 3 ماتشات عربية خالصة، ومنتخب واحد كان طرف فيهم كلهم. مين هو؟', answer: 'السعودية', aliases: ['المنتخب السعودي'], decoys: ['تونس', 'المغرب', 'مصر'] },
  { id: 'fm7', category: 'football', text: 'إيه أبعد دور وصل له منتخب عربي في تاريخ كأس العالم؟', answer: 'نصف النهائي', aliases: ['نص النهائي', 'دور الأربعة'], decoys: ['ربع النهائي', 'دور الـ16', 'النهائي'] },
  { id: 'fm8', category: 'football', text: 'لحد مونديال 2026، الرقم القياسي لأهداف لاعب عربي واحد في تاريخ كأس العالم كام هدف؟', answer: '3', aliases: ['تلاتة', 'ثلاثة'], decoys: ['4', '5', '6'] },
  { id: 'fm9', category: 'football', text: 'كام منتخب عربي شارك في كأس العالم لحد مونديال 2026؟', answer: '10', aliases: ['عشرة', 'عشر'], decoys: ['8', '9', '12'] },

  // دوري أبطال أوروبا
  { id: 'fu2', level: 'hard', category: 'football', text: 'أنهي نادي عنده أطول سلسلة انتصارات ورا بعض في تاريخ دوري أبطال أوروبا؟', answer: 'بايرن ميونخ', aliases: ['بايرن', 'بايرن ميونيخ'], decoys: ['ريال مدريد', 'برشلونة', 'مانشستر سيتي'] },
  { id: 'fu3', level: 'hard', category: 'football', text: 'مين أصغر لاعب سجل في نهائي دوري أبطال أوروبا؟', answer: 'باتريك كلويفرت', aliases: ['كلويفرت'], decoys: ['ليونيل ميسي', 'راؤول جونزاليس', 'كيليان مبابي'] },
  { id: 'fu4', level: 'hard', category: 'football', text: 'مين أكبر لاعب سجل في نهائي دوري أبطال أوروبا؟', answer: 'باولو مالديني', aliases: ['مالديني'], decoys: ['رايان جيجز', 'كلارنس سيدورف', 'سيرجيو راموس'] },
  { id: 'fu5', level: 'hard', category: 'football', text: 'مين صاحب أسرع هدف في تاريخ دوري أبطال أوروبا (بعد 10 ثواني بس)؟', answer: 'روي ماكاي', aliases: ['ماكاي'], decoys: ['أليساندرو ديل بييرو', 'رافائيل فان دير فارت', 'جيلبرتو سيلفا'] },
  { id: 'fu6', category: 'football', text: 'اسم «كأس أوروبا للأندية» اتغير لـ«دوري أبطال أوروبا» سنة كام؟', answer: '1992', decoys: ['1995', '1989', '1999'] },
  { id: 'fu7', category: 'football', text: 'أول نهائي دوري أبطال أوروبا بين فريقين من نفس المدينة كان سنة كام؟', answer: '2014', decoys: ['2012', '2008', '2003'] },
  { id: 'fu8', category: 'football', text: 'أنهي دولة أنديتها كسبت دوري أبطال أوروبا أكتر مرات؟', answer: 'إسبانيا', decoys: ['إنجلترا', 'إيطاليا', 'ألمانيا'] },
  { id: 'fu9', category: 'football', text: 'في نظام دوري أبطال أوروبا الجديد (من 2024-2025)، كل فريق بيلعب كام ماتش في مرحلة الدوري؟', answer: '8', aliases: ['تمانية', 'ثمانية'], decoys: ['6', '10', '12'] },
  { id: 'fu10', level: 'hard', category: 'football', text: 'كريستيانو رونالدو سجل كام هدف في دوري أبطال أوروبا؟', answer: '140', decoys: ['129', '135', '145'] },
  { id: 'fu11', category: 'football', text: 'كام فريق بيشارك في دوري أبطال أوروبا بالنظام الجديد (من 2024-2025)؟', answer: '36', decoys: ['32', '40', '48'] },
  { id: 'fu12', level: 'hard', category: 'football', text: 'نادي من رومانيا كسب دوري أبطال أوروبا مرة واحدة بس، مين هو؟', answer: 'ستيوا بوخارست', aliases: ['ستيوا'], decoys: ['دينامو بوخارست', 'رابيد بوخارست', 'سي إف آر كلوج'] },
  { id: 'fu13', category: 'football', text: 'أكتر نادي إيطالي كسب دوري أبطال أوروبا؟', answer: 'ميلان', aliases: ['أي سي ميلان', 'إيه سي ميلان'], decoys: ['يوفنتوس', 'إنتر ميلان', 'روما'] },
  { id: 'fu14', category: 'football', text: 'كام نادي إنجليزي كسب دوري أبطال أوروبا؟', answer: '6', aliases: ['ستة', 'ست'], decoys: ['4', '5', '7'] },
  { id: 'fu15', category: 'football', text: 'مين كسب دوري أبطال أوروبا 2013؟', answer: 'بايرن ميونخ', aliases: ['بايرن', 'بايرن ميونيخ'], decoys: ['بوروسيا دورتموند', 'برشلونة', 'ريال مدريد'] },
  { id: 'fu16', category: 'football', text: 'أكتر نادي هولندي كسب دوري أبطال أوروبا؟', answer: 'أياكس', aliases: ['أياكس أمستردام'], decoys: ['بي إس في أيندهوفن', 'فينورد', 'إيه زد ألكمار'] },
  { id: 'fu17', level: 'hard', category: 'football', text: 'مين اللي كسب دوري أبطال أوروبا كلاعب وكمدرب، وكسب جايزة الفيفا لأفضل لاعب في العالم؟', answer: 'زين الدين زيدان', aliases: ['زيدان'], decoys: ['كارلو أنشيلوتي', 'بيب جوارديولا', 'فرانك ريكارد'] },
  { id: 'fu18', level: 'hard', category: 'football', text: 'أنهي نادي خسر أكتر ماتشات في تاريخ دوري أبطال أوروبا؟', answer: 'ريال مدريد', aliases: ['الريال'], decoys: ['دينامو كييف', 'بنفيكا', 'بورتو'] },

  // ------------------------------------------------------------------- أفلام
  { id: 'm4', category: 'movies', text: 'إيه أول فيلم كسب أوسكار أحسن فيلم؟', answer: 'أجنحة', aliases: ['وينجز'], decoys: ['ذهب مع الريح', 'كازابلانكا', 'المغني الجاز'] },
  { id: 'hm1', level: 'hard', category: 'movies', text: 'مين مخرج فيلم «باب الحديد»؟', answer: 'يوسف شاهين', decoys: ['صلاح أبو سيف', 'حسن الإمام', 'عاطف الطيب'] },
  { id: 'hm2', level: 'hard', category: 'movies', text: 'مين بطل فيلم «الكيت كات»؟', answer: 'محمود عبد العزيز', decoys: ['أحمد زكي', 'نور الشريف', 'يحيى الفخراني'] },
  { id: 'hm3', level: 'hard', category: 'movies', text: 'مين مخرج فيلم «الأب الروحي» (العراب) سنة 1972؟', answer: 'فرانسيس فورد كوبولا', aliases: ['كوبولا'], decoys: ['مارتن سكورسيزي', 'ستانلي كوبريك', 'بريان دي بالما'] },
  { id: 'hm4', level: 'hard', category: 'movies', text: 'فيلم «تايتانيك» كسب كام جايزة أوسكار؟', answer: '11', decoys: ['9', '12', '14'] },
  { id: 'hm5', level: 'hard', category: 'movies', text: 'إيه اسم الكلب في فيلم «القناع» بطولة جيم كاري؟', answer: 'مايلو', decoys: ['ماكس', 'بادي', 'روكي'] },
  { id: 'hm6', level: 'hard', category: 'movies', text: 'مين بطلة فيلم «دعاء الكروان»؟', answer: 'فاتن حمامة', decoys: ['شادية', 'سعاد حسني', 'ماجدة'] },
  { id: 'hm7', level: 'hard', category: 'movies', text: 'عادل إمام عمل شخصية «سرحان عبد البصير» في أنهي مسرحية؟', answer: 'شاهد ما شافش حاجة', decoys: ['مدرسة المشاغبين', 'الواد سيد الشغال', 'الزعيم'] },
  { id: 'hm8', level: 'hard', category: 'movies', text: 'مين مخرج فيلم «إنسبشن»؟', answer: 'كريستوفر نولان', aliases: ['نولان'], decoys: ['دينيس فيلنوف', 'ريدلي سكوت', 'ديفيد فينشر'] },

  // ------------------------------------------------------------- أعلام بلاد
  { id: 'g1', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'بوتان', decoys: ['لاوس', 'ميانمار', 'كمبوديا'], imageUrl: 'https://flagcdn.com/w320/bt.png' },
  { id: 'g2', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'كازاخستان', decoys: ['أوزبكستان', 'طاجيكستان', 'أذربيجان'], imageUrl: 'https://flagcdn.com/w320/kz.png' },
  { id: 'g3', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'نيبال', decoys: ['سريلانكا', 'بنجلاديش', 'التبت'], imageUrl: 'https://flagcdn.com/w320/np.png' },
  { id: 'g4', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'موزمبيق', decoys: ['أنجولا', 'زامبيا', 'زيمبابوي'], imageUrl: 'https://flagcdn.com/w320/mz.png' },
  { id: 'g5', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'سريلانكا', decoys: ['المالديف', 'ميانمار', 'ماليزيا'], imageUrl: 'https://flagcdn.com/w320/lk.png' },
  { id: 'hg1', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'قيرغيزستان', decoys: ['طاجيكستان', 'تركمانستان', 'منغوليا'], imageUrl: 'https://flagcdn.com/w320/kg.png' },
  { id: 'hg2', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'بوركينا فاسو', decoys: ['مالي', 'غانا', 'الكاميرون'], imageUrl: 'https://flagcdn.com/w320/bf.png' },
  { id: 'hg3', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'إريتريا', decoys: ['جيبوتي', 'الصومال', 'جنوب السودان'], imageUrl: 'https://flagcdn.com/w320/er.png' },
  { id: 'hg4', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'كيريباتي', decoys: ['توفالو', 'فيجي', 'ساموا'], imageUrl: 'https://flagcdn.com/w320/ki.png' },
  { id: 'hg5', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'سورينام', decoys: ['غيانا', 'باراجواي', 'بوليفيا'], imageUrl: 'https://flagcdn.com/w320/sr.png' },
  { id: 'hg6', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'تركمانستان', decoys: ['أوزبكستان', 'قيرغيزستان', 'أذربيجان'], imageUrl: 'https://flagcdn.com/w320/tm.png' },
  { id: 'hg7', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'منغوليا', decoys: ['كازاخستان', 'بوتان', 'لاوس'], imageUrl: 'https://flagcdn.com/w320/mn.png' },
  { id: 'hg8', level: 'hard', category: 'flags', text: 'علم أنهي دولة ده؟', answer: 'بوتسوانا', decoys: ['ناميبيا', 'زامبيا', 'ليسوتو'], imageUrl: 'https://flagcdn.com/w320/bw.png' },

  // ------------------------------------- أغاني مصرية (من التمانينات لحد دلوقتي)
  { id: 'hs1', level: 'hard', category: 'songs', text: 'أغنية «كامننا» كانت في أنهي فيلم؟', answer: 'إسماعيلية رايح جاي', decoys: ['صعيدي في الجامعة الأمريكية', 'همام في أمستردام', 'حرامية في كي جي تو'] },
  { id: 'hs2', level: 'hard', category: 'songs', text: 'أغنية «علّي صوتك بالغنا» لمحمد منير كانت في أنهي فيلم؟', answer: 'المصير', decoys: ['حدوتة مصرية', 'إسكندرية كمان وكمان', 'اليوم السادس'] },
  { id: 'hs3', level: 'hard', category: 'songs', text: 'أبو غنّى «3 دقات» مع مين؟', answer: 'يسرا', decoys: ['ليلى علوي', 'إلهام شاهين', 'نبيلة عبيد'] },
  { id: 'hs4', level: 'hard', category: 'songs', text: 'أغنية «بشرة خير» نزلت سنة كام؟', answer: '2014', decoys: ['2012', '2016', '2013'] },
  { id: 'hs7', level: 'hard', category: 'songs', text: 'مين غنّى «لولاكي» سنة 1988؟', answer: 'علي حميدة', decoys: ['حميد الشاعري', 'هشام عباس', 'علاء عبد الخالق'] },
  { id: 'hs8', level: 'hard', category: 'songs', text: 'مين غنّى «آه لو لعبت يا زهر»؟', answer: 'أحمد شيبة', decoys: ['محمود الليثي', 'عبد الباسط حمودة', 'حكيم'] },
];

export const QUESTIONS: Question[] = [...BASE_QUESTIONS, ...EXTRA_QUESTIONS, ...HARD_QUESTIONS, ...PACK4A, ...PACK4B, ...PACK4C];
