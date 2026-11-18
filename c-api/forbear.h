#ifndef FORBEAR_H
#define FORBEAR_H
#include <stdint.h>
#include <stddef.h>

#if defined(__GNUC__) || defined(__clang__)
#define FB_FLOAT32_NAN __builtin_nanf("")
#define FB_FLOAT64_NAN __builtin_nan("")
#else
#include <math.h>
#define FB_FLOAT32_NAN NAN
#define FB_FLOAT64_NAN ((double)NAN)
#endif

// ====== BEGIN AUTO GENERATED PORTION ======
#if defined(_WIN32)
typedef struct { int64_t count; uint8_t *data; } fb_String;
typedef struct fb_Vector3 fb_Vector3;
struct fb_Vector3 {
    float x;
    float y;
    float z;
};
_Static_assert(sizeof(fb_Vector3) == 12, "fb_Vector3");
_Static_assert(offsetof(fb_Vector3, x) == 0, "fb_Vector3.x");
_Static_assert(offsetof(fb_Vector3, y) == 4, "fb_Vector3.y");
_Static_assert(offsetof(fb_Vector3, z) == 8, "fb_Vector3.z");

typedef struct fb_Scrolling_State fb_Scrolling_State;
typedef struct fb_Vector2 fb_Vector2;
struct fb_Vector2 {
    float x;
    float y;
};
_Static_assert(sizeof(fb_Vector2) == 8, "fb_Vector2");
_Static_assert(offsetof(fb_Vector2, x) == 0, "fb_Vector2.x");
_Static_assert(offsetof(fb_Vector2, y) == 4, "fb_Vector2.y");

typedef struct fb_Scheduled_Scroll fb_Scheduled_Scroll;
struct fb_Scheduled_Scroll {
    _Bool defined;
    _Bool defined_this_frame;
    fb_Vector2 position;
    _Bool animate;
};
_Static_assert(sizeof(fb_Scheduled_Scroll) == 16, "fb_Scheduled_Scroll");
_Static_assert(offsetof(fb_Scheduled_Scroll, defined) == 0, "fb_Scheduled_Scroll.defined");
_Static_assert(offsetof(fb_Scheduled_Scroll, defined_this_frame) == 1, "fb_Scheduled_Scroll.defined_this_frame");
_Static_assert(offsetof(fb_Scheduled_Scroll, position) == 4, "fb_Scheduled_Scroll.position");
_Static_assert(offsetof(fb_Scheduled_Scroll, animate) == 12, "fb_Scheduled_Scroll.animate");

struct fb_Scrolling_State {
    fb_Vector2 offset;
    fb_Vector2 effective_offset;
    fb_Scheduled_Scroll scheduled_scroll;
};
_Static_assert(sizeof(fb_Scrolling_State) == 32, "fb_Scrolling_State");
_Static_assert(offsetof(fb_Scrolling_State, offset) == 0, "fb_Scrolling_State.offset");
_Static_assert(offsetof(fb_Scrolling_State, effective_offset) == 8, "fb_Scrolling_State.effective_offset");
_Static_assert(offsetof(fb_Scrolling_State, scheduled_scroll) == 16, "fb_Scrolling_State.scheduled_scroll");

typedef struct fb_Complete_Style fb_Complete_Style;
typedef struct fb_Background fb_Background;
typedef uint8_t fb_Background_Kind;
#define FB_BACKGROUND_KIND_COLOR 0
#define FB_BACKGROUND_KIND_GRADIENT 1

typedef struct fb_Vector4 fb_Vector4;
struct fb_Vector4 {
    float x;
    float y;
    float z;
    float w;
};
_Static_assert(sizeof(fb_Vector4) == 16, "fb_Vector4");
_Static_assert(offsetof(fb_Vector4, x) == 0, "fb_Vector4.x");
_Static_assert(offsetof(fb_Vector4, y) == 4, "fb_Vector4.y");
_Static_assert(offsetof(fb_Vector4, z) == 8, "fb_Vector4.z");
_Static_assert(offsetof(fb_Vector4, w) == 12, "fb_Vector4.w");

typedef struct fb_Linear_Gradient fb_Linear_Gradient;
typedef struct fb_Gradient_Stop fb_Gradient_Stop;
struct fb_Gradient_Stop {
    fb_Vector4 color;
    float position;
};
_Static_assert(sizeof(fb_Gradient_Stop) == 20, "fb_Gradient_Stop");
_Static_assert(offsetof(fb_Gradient_Stop, color) == 0, "fb_Gradient_Stop.color");
_Static_assert(offsetof(fb_Gradient_Stop, position) == 16, "fb_Gradient_Stop.position");

typedef struct { int64_t count; fb_Gradient_Stop *data; } fb_View_Gradient_Stop;

struct fb_Linear_Gradient {
    fb_View_Gradient_Stop stops;
    fb_Vector2 direction;
};
_Static_assert(sizeof(fb_Linear_Gradient) == 24, "fb_Linear_Gradient");
_Static_assert(offsetof(fb_Linear_Gradient, stops) == 0, "fb_Linear_Gradient.stops");
_Static_assert(offsetof(fb_Linear_Gradient, direction) == 16, "fb_Linear_Gradient.direction");

struct fb_Background {
    fb_Background_Kind kind;
    union {
    fb_Vector4 color;
    fb_Linear_Gradient gradient;
    };
};
_Static_assert(sizeof(fb_Background) == 32, "fb_Background");
_Static_assert(offsetof(fb_Background, kind) == 0, "fb_Background.kind");

typedef struct fb_Sides fb_Sides;
struct fb_Sides {
    fb_Vector2 x;
    fb_Vector2 y;
};
_Static_assert(sizeof(fb_Sides) == 16, "fb_Sides");
_Static_assert(offsetof(fb_Sides, x) == 0, "fb_Sides.x");
_Static_assert(offsetof(fb_Sides, y) == 8, "fb_Sides.y");

typedef uint32_t fb_Border_Style;
#define FB_BORDER_STYLE_SOLID 0
#define FB_BORDER_STYLE_DASHED 1

typedef struct fb_Shadow fb_Shadow;
struct fb_Shadow {
    fb_Sides offset;
    float blur_radius;
    float spread;
    fb_Vector4 color;
};
_Static_assert(sizeof(fb_Shadow) == 40, "fb_Shadow");
_Static_assert(offsetof(fb_Shadow, offset) == 0, "fb_Shadow.offset");
_Static_assert(offsetof(fb_Shadow, blur_radius) == 16, "fb_Shadow.blur_radius");
_Static_assert(offsetof(fb_Shadow, spread) == 20, "fb_Shadow.spread");
_Static_assert(offsetof(fb_Shadow, color) == 24, "fb_Shadow.color");

typedef struct fb_Font fb_Font;
struct fb_Font {
    fb_String memory;
    void * raster_face;
    _Alignas(8) uint8_t shaping_font[72];
    uint16_t key;
    uint16_t weight;
};
_Static_assert(sizeof(fb_Font) == 104, "fb_Font");
_Static_assert(offsetof(fb_Font, memory) == 0, "fb_Font.memory");
_Static_assert(offsetof(fb_Font, raster_face) == 16, "fb_Font.raster_face");
_Static_assert(offsetof(fb_Font, shaping_font) == 24, "fb_Font.shaping_font");
_Static_assert(offsetof(fb_Font, key) == 96, "fb_Font.key");
_Static_assert(offsetof(fb_Font, weight) == 98, "fb_Font.weight");

typedef uint32_t fb_Language;
#define FB_LANGUAGE_DONT_KNOW 0
#define FB_LANGUAGE_A_HMAO 541347144
#define FB_LANGUAGE_AARI 541676097
#define FB_LANGUAGE_ABAZA 541147713
#define FB_LANGUAGE_ABKHAZIAN 541803073
#define FB_LANGUAGE_ACHI 542262081
#define FB_LANGUAGE_ACHOLI 541606721
#define FB_LANGUAGE_ADYGHE 542721089
#define FB_LANGUAGE_AFAR 542262849
#define FB_LANGUAGE_AFRIKAANS 541804097
#define FB_LANGUAGE_AGAW 542590785
#define FB_LANGUAGE_AITON 542067009
#define FB_LANGUAGE_AKAN 541150017
#define FB_LANGUAGE_ALBANIAN 541675859
#define FB_LANGUAGE_ALSATIAN 542329921
#define FB_LANGUAGE_ALTAI 542395457
#define FB_LANGUAGE_ALUO 541150809
#define FB_LANGUAGE_AMERICAN_PHONETIC 1213222977
#define FB_LANGUAGE_AMHARIC 541609281
#define FB_LANGUAGE_ANGLO_SAXON 541544001
#define FB_LANGUAGE_ARABIC 541151809
#define FB_LANGUAGE_ARAGONESE 541545025
#define FB_LANGUAGE_ARAKANESE 541807169
#define FB_LANGUAGE_ARAKWAL 542591826
#define FB_LANGUAGE_ARMENIAN 541415752
#define FB_LANGUAGE_ARMENIAN_EAST 809851208
#define FB_LANGUAGE_AROMANIAN 542135634
#define FB_LANGUAGE_ARPITAN 542134854
#define FB_LANGUAGE_ASSAMESE 541938497
#define FB_LANGUAGE_ASTURIAN 542397249
#define FB_LANGUAGE_ATHAPASKAN 541611073
#define FB_LANGUAGE_ATSINA 542331969
#define FB_LANGUAGE_AVAR 542266945
#define FB_LANGUAGE_AVATIME 542004801
#define FB_LANGUAGE_AWADHI 541153089
#define FB_LANGUAGE_AYMARA 541940033
#define FB_LANGUAGE_AZERBAIJANI 541416001
#define FB_LANGUAGE_BADAGA 541344066
#define FB_LANGUAGE_BAGHELKHANDI 541540674
#define FB_LANGUAGE_BAGRI 542197570
#define FB_LANGUAGE_BALANTE 542002242
#define FB_LANGUAGE_BALINESE 541999426
#define FB_LANGUAGE_BALKAR 541868354
#define FB_LANGUAGE_BALTI 542395458
#define FB_LANGUAGE_BALUCHI 541674562
#define FB_LANGUAGE_BAMBARA 541216066
#define FB_LANGUAGE_BAMILEKE 541871426
#define FB_LANGUAGE_BANDA 809779522
#define FB_LANGUAGE_BANDJALANG 542721090
#define FB_LANGUAGE_BANGLA 542000450
#define FB_LANGUAGE_BASHKIR 541610818
#define FB_LANGUAGE_BASQUE 542201157
#define FB_LANGUAGE_BATAK 541807682
#define FB_LANGUAGE_BATAK_ALAS_KLUET 542790722
#define FB_LANGUAGE_BATAK_ANGKOLA 541215553
#define FB_LANGUAGE_BATAK_DAIRI 541348930
#define FB_LANGUAGE_BATAK_KARO 542659650
#define FB_LANGUAGE_BATAK_MANDAILING 541938754
#define FB_LANGUAGE_BATAK_SIMALUNGUN 542331970
#define FB_LANGUAGE_BATAK_TOBA 541278786
#define FB_LANGUAGE_BAULE 542458178
#define FB_LANGUAGE_BAVARIAN 542261570
#define FB_LANGUAGE_BELARUSIAN 541869378
#define FB_LANGUAGE_BEMBA 541934914
#define FB_LANGUAGE_BENCH 541606722
#define FB_LANGUAGE_BERBER 542261826
#define FB_LANGUAGE_BETI 541676610
#define FB_LANGUAGE_BETTE_KURUMA 541218136
#define FB_LANGUAGE_BHILI 541673538
#define FB_LANGUAGE_BHOJPURI 542066754
#define FB_LANGUAGE_BHUTANESE 542005828
#define FB_LANGUAGE_BIBLE_CREE 542262082
#define FB_LANGUAGE_BIKOL 541804866
#define FB_LANGUAGE_BILEN 541870402
#define FB_LANGUAGE_BISHNUPRIYA_MANIPURI 542724162
#define FB_LANGUAGE_BISLAMA 542329154
#define FB_LANGUAGE_BLACKFOOT 541477698
#define FB_LANGUAGE_BODO 542659138
#define FB_LANGUAGE_BOSNIAN 542330690
#define FB_LANGUAGE_BOUYEI 541279056
#define FB_LANGUAGE_BRAHUI 541610562
#define FB_LANGUAGE_BRAJ_BHASHA 541676098
#define FB_LANGUAGE_BRETON 541413954
#define FB_LANGUAGE_BUGIS 541545794
#define FB_LANGUAGE_BULGARIAN 542263106
#define FB_LANGUAGE_BUMTHANGKHA 542788171
#define FB_LANGUAGE_BURMESE 541938242
#define FB_LANGUAGE_BURUSHASKI 541807426
#define FB_LANGUAGE_CAJUN_FRENCH 541282886
#define FB_LANGUAGE_CARRIER 542265923
#define FB_LANGUAGE_CATALAN 542392643
#define FB_LANGUAGE_CAYUGA 542720323
#define FB_LANGUAGE_CEBUANO 541214019
#define FB_LANGUAGE_CENTRAL_YUPIK 542462789
#define FB_LANGUAGE_CHAHA_GURAGE 541542467
#define FB_LANGUAGE_CHAMORRO 541149251
#define FB_LANGUAGE_CHATTISGARHI 541608003
#define FB_LANGUAGE_CHECHEN 541411395
#define FB_LANGUAGE_CHEROKEE 542263363
#define FB_LANGUAGE_CHEYENNE 542722115
#define FB_LANGUAGE_CHICHEWA 541673539
#define FB_LANGUAGE_CHIGA 541542211
#define FB_LANGUAGE_CHIMILA 541540931
#define FB_LANGUAGE_CHIN 542001489
#define FB_LANGUAGE_CHINANTEC 1313358659
#define FB_LANGUAGE_CHINESE_PHONETIC 542132314
#define FB_LANGUAGE_CHINESE_SIMPLIFIED 542328922
#define FB_LANGUAGE_CHINESE_TRADITIONAL 542394458
#define FB_LANGUAGE_CHINESE_TRADITIONAL_HONG_KONG 541608026
#define FB_LANGUAGE_CHINESE_TRADITIONAL_MACAO 1297369178
#define FB_LANGUAGE_CHIPEWYAN 542132291
#define FB_LANGUAGE_CHITTAGONIAN 541545539
#define FB_LANGUAGE_CHOCTAW 542066755
#define FB_LANGUAGE_CHUKCHI 541804611
#define FB_LANGUAGE_CHURCH_SLAVONIC 541872963
#define FB_LANGUAGE_CHUUKESE 810240067
#define FB_LANGUAGE_CHUVASH 542459971
#define FB_LANGUAGE_COMORIAN 542264643
#define FB_LANGUAGE_COMOX 542068547
#define FB_LANGUAGE_COPTIC 542134083
#define FB_LANGUAGE_CORNISH 542265155
#define FB_LANGUAGE_CORSICAN 542330691
#define FB_LANGUAGE_CREE 541413955
#define FB_LANGUAGE_CREOLES 542134339
#define FB_LANGUAGE_CRIMEAN_TATAR 542396995
#define FB_LANGUAGE_CRIOULO 541148491
#define FB_LANGUAGE_CROATIAN 542528072
#define FB_LANGUAGE_CYPRIOT_ARABIC 542720833
#define FB_LANGUAGE_CZECH 542724931
#define FB_LANGUAGE_DAGBANI 541540676
#define FB_LANGUAGE_DAN 541740612
#define FB_LANGUAGE_DANGME 541544004
#define FB_LANGUAGE_DANISH 541999428
#define FB_LANGUAGE_DARGWA 542261572
#define FB_LANGUAGE_DARI 541676100
#define FB_LANGUAGE_DAYI 542654788
#define FB_LANGUAGE_DEFAULT 1953261156
#define FB_LANGUAGE_DEHONG_DAI 541344852
#define FB_LANGUAGE_DHANGU 541542468
#define FB_LANGUAGE_DHIVEHI 542525764
#define FB_LANGUAGE_DHUWAL 541742404
#define FB_LANGUAGE_DIMLI 542198084
#define FB_LANGUAGE_DINKA 541806148
#define FB_LANGUAGE_DIVEHI 542525764
#define FB_LANGUAGE_DJAMBARRPUYNGU 810699332
#define FB_LANGUAGE_DOGRI 542066500
#define FB_LANGUAGE_DOGRI_MACROLANGUAGE 542263108
#define FB_LANGUAGE_DUNGAN 542004548
#define FB_LANGUAGE_DUTCH 541346894
#define FB_LANGUAGE_DZONGKHA 542005828
#define FB_LANGUAGE_EASTERN_ABENAKI 542196033
#define FB_LANGUAGE_EASTERN_CHAM 541936195
#define FB_LANGUAGE_EASTERN_CREE 542262085
#define FB_LANGUAGE_EASTERN_MANINKAKAN 541805893
#define FB_LANGUAGE_EASTERN_PWO_KAREN 542132811
#define FB_LANGUAGE_EBIRA 541672005
#define FB_LANGUAGE_EDO 542065733
#define FB_LANGUAGE_EFIK 541673029
#define FB_LANGUAGE_EMBERA_BAUDO 541279298
#define FB_LANGUAGE_EMBERA_CATIO 542069827
#define FB_LANGUAGE_EMBERA_CHAMI 541674819
#define FB_LANGUAGE_EMBERA_TADO 541279316
#define FB_LANGUAGE_ENGLISH 541544005
#define FB_LANGUAGE_EPENA 541149779
#define FB_LANGUAGE_ERZYA 542790213
#define FB_LANGUAGE_ESPERANTO 542069838
#define FB_LANGUAGE_ESTONIAN 541676613
#define FB_LANGUAGE_EVEN 542004805
#define FB_LANGUAGE_EVENKI 541808197
#define FB_LANGUAGE_EWE 541415237
#define FB_LANGUAGE_FALAM_CHIN 541868360
#define FB_LANGUAGE_FANG 810434886
#define FB_LANGUAGE_FANTI 542392646
#define FB_LANGUAGE_FAROESE 542330694
#define FB_LANGUAGE_FEFE 542133574
#define FB_LANGUAGE_FIJIAN 541674054
#define FB_LANGUAGE_FILIPINO 541870416
#define FB_LANGUAGE_FINNISH 542001478
#define FB_LANGUAGE_FLEMISH 541412422
#define FB_LANGUAGE_FON 542003014
#define FB_LANGUAGE_FOREST_ENETS 541412934
#define FB_LANGUAGE_FRENCH 541151814
#define FB_LANGUAGE_FRENCH_ANTILLEAN 541999430
#define FB_LANGUAGE_FRISIAN 541676102
#define FB_LANGUAGE_FRIULIAN 541872710
#define FB_LANGUAGE_FULAH 541873478
#define FB_LANGUAGE_FUTA 541152326
#define FB_LANGUAGE_GA 541344071
#define FB_LANGUAGE_GAGAUZ 541540679
#define FB_LANGUAGE_GALICIAN 541868359
#define FB_LANGUAGE_GANDA 541545804
#define FB_LANGUAGE_GARHWALI 542589255
#define FB_LANGUAGE_GARO 542069319
#define FB_LANGUAGE_GARSHUNI 542261575
#define FB_LANGUAGE_GEBA_KAREN 542201419
#define FB_LANGUAGE_GEEZ 542786887
#define FB_LANGUAGE_GEORGIAN 542392651
#define FB_LANGUAGE_GEPO 542132057
#define FB_LANGUAGE_GERMAN 542459204
#define FB_LANGUAGE_GIKUYU 541804875
#define FB_LANGUAGE_GILAKI 541805639
#define FB_LANGUAGE_GILBERTESE 810305863
#define FB_LANGUAGE_GILYAK 541870407
#define FB_LANGUAGE_GITHABUL 541608263
#define FB_LANGUAGE_GOGO 541544263
#define FB_LANGUAGE_GONDI 542003015
#define FB_LANGUAGE_GREEK 541871173
#define FB_LANGUAGE_GREENLANDIC 542003783
#define FB_LANGUAGE_GUARANI 541152583
#define FB_LANGUAGE_GUINEA 542133063
#define FB_LANGUAGE_GUJARATI 541742407
#define FB_LANGUAGE_GUMATJ 542002759
#define FB_LANGUAGE_GUMUZ 542788935
#define FB_LANGUAGE_GUPAPUYNGU 541480263
#define FB_LANGUAGE_GUSII 542790983
#define FB_LANGUAGE_HAIDA 810107208
#define FB_LANGUAGE_HAITIAN_CREOLE 541671752
#define FB_LANGUAGE_HALKOMELEM 542266696
#define FB_LANGUAGE_HAMMER_BANNA 541999688
#define FB_LANGUAGE_HARARI 541676104
#define FB_LANGUAGE_HARAUTI 542261576
#define FB_LANGUAGE_HARYANVI 541280066
#define FB_LANGUAGE_HAUSA 542458184
#define FB_LANGUAGE_HAVASUPAI_WALAPAI_YAVAPAI 541480281
#define FB_LANGUAGE_HAWAIIAN 542589256
#define FB_LANGUAGE_HAYA 542720328
#define FB_LANGUAGE_HAZARAGI 542785864
#define FB_LANGUAGE_HEBREW 542267209
#define FB_LANGUAGE_HEILTSUK 541672776
#define FB_LANGUAGE_HERERO 542262600
#define FB_LANGUAGE_HIGH_MARI 541150536
#define FB_LANGUAGE_HILIGAYNON 541870408
#define FB_LANGUAGE_HINDI 542001480
#define FB_LANGUAGE_HINDKO 541347400
#define FB_LANGUAGE_HIRI_MOTU 542068040
#define FB_LANGUAGE_HMONG 542002504
#define FB_LANGUAGE_HMONG_DAW 542594893
#define FB_LANGUAGE_HMONG_SHUAT 542788936
#define FB_LANGUAGE_HO 538988360
#define FB_LANGUAGE_HUNGARIAN 542004552
#define FB_LANGUAGE_IBAN 541147721
#define FB_LANGUAGE_IBIBIO 541213257
#define FB_LANGUAGE_ICELANDIC 541872969
#define FB_LANGUAGE_IDO 542065737
#define FB_LANGUAGE_IGBO 542065225
#define FB_LANGUAGE_IJO 542067273
#define FB_LANGUAGE_ILOKANO 542067785
#define FB_LANGUAGE_INARI_SAMI 541938505
#define FB_LANGUAGE_INDONESIAN 541347401
#define FB_LANGUAGE_INGUSH 541544009
#define FB_LANGUAGE_INTERLINGUA 541150793
#define FB_LANGUAGE_INTERLINGUE 541412425
#define FB_LANGUAGE_INUKTITUT 542461513
#define FB_LANGUAGE_INUPIAT 541806665
#define FB_LANGUAGE_IPA_PHONETIC 542134345
#define FB_LANGUAGE_IRISH 541676105
#define FB_LANGUAGE_IRISH_TRADITIONAL 542397001
#define FB_LANGUAGE_IRULA 542462537
#define FB_LANGUAGE_ITALIAN 541152329
#define FB_LANGUAGE_JAMAICAN_CREOLE 541933898
#define FB_LANGUAGE_JAPANESE 541999434
#define FB_LANGUAGE_JAVANESE 542523722
#define FB_LANGUAGE_JENNU_KURUMA 541742424
#define FB_LANGUAGE_JUDEO_TAT 542393418
#define FB_LANGUAGE_JULA 541873482
#define FB_LANGUAGE_KABARDIAN 541213003
#define FB_LANGUAGE_KABYLE 809648459
#define FB_LANGUAGE_KACHCHI 541278539
#define FB_LANGUAGE_KADIWEU 541278795
#define FB_LANGUAGE_KALENJIN 541868363
#define FB_LANGUAGE_KALMYK 541936715
#define FB_LANGUAGE_KAMBA 541216075
#define FB_LANGUAGE_KANAUJI 541739586
#define FB_LANGUAGE_KANNADA 541999435
#define FB_LANGUAGE_KANURI 542264907
#define FB_LANGUAGE_KAQCHIKEL 541802819
#define FB_LANGUAGE_KARACHAY 542261579
#define FB_LANGUAGE_KARAIM 541938251
#define FB_LANGUAGE_KARAKALPAK 541807179
#define FB_LANGUAGE_KARELIAN 541872715
#define FB_LANGUAGE_KAREN 542003787
#define FB_LANGUAGE_KASHMIRI 541610827
#define FB_LANGUAGE_KASHUBIAN 541217603
#define FB_LANGUAGE_KATE 541543755
#define FB_LANGUAGE_KAZAKH 542785867
#define FB_LANGUAGE_KEBENA 541214027
#define FB_LANGUAGE_KEKCHI 541803851
#define FB_LANGUAGE_KHAKASS 541149259
#define FB_LANGUAGE_KHAMTI_SHAN 542394443
#define FB_LANGUAGE_KHAMYANG 542462795
#define FB_LANGUAGE_KHANTY_KAZIM 541804619
#define FB_LANGUAGE_KHANTY_SHURISHKAR 542328907
#define FB_LANGUAGE_KHANTY_VAKHI 542525515
#define FB_LANGUAGE_KHASI 541676363
#define FB_LANGUAGE_KHENGKHA 541477720
#define FB_LANGUAGE_KHINALUG 541739595
#define FB_LANGUAGE_KHMER 541935691
#define FB_LANGUAGE_KHORASANI_TURKIC 542788939
#define FB_LANGUAGE_KHOWAR 542591051
#define FB_LANGUAGE_KHUTSURI_GEORGIAN 541411147
#define FB_LANGUAGE_KICHE 541283665
#define FB_LANGUAGE_KIKONGO 542003019
#define FB_LANGUAGE_KILDIN_SAMI 541938507
#define FB_LANGUAGE_KINYARWANDA 541152594
#define FB_LANGUAGE_KIRMANJKI 542460235
#define FB_LANGUAGE_KISII 542329163
#define FB_LANGUAGE_KITUBA 542591821
#define FB_LANGUAGE_KODAGU 541347659
#define FB_LANGUAGE_KOKNI 542001995
#define FB_LANGUAGE_KOMI 541937483
#define FB_LANGUAGE_KOMI_PERMYAK 542134091
#define FB_LANGUAGE_KOMI_ZYRIAN 542789451
#define FB_LANGUAGE_KOMO 542068043
#define FB_LANGUAGE_KOMSO 542330187
#define FB_LANGUAGE_KONGO 810438475
#define FB_LANGUAGE_KONKANI 541806411
#define FB_LANGUAGE_KOORETE 542397003
#define FB_LANGUAGE_KOREAN 542265163
#define FB_LANGUAGE_KOREAN_OLD_HANGUL 541609803
#define FB_LANGUAGE_KORYAK 541808971
#define FB_LANGUAGE_KOSRAEAN 542330699
#define FB_LANGUAGE_KPELLE 541872203
#define FB_LANGUAGE_KPELLE_LIBERIA 541413464
#define FB_LANGUAGE_KRIO 541676107
#define FB_LANGUAGE_KRYMCHAK 542393162
#define FB_LANGUAGE_KUANYAMA 541152587
#define FB_LANGUAGE_KUBE 541476683
#define FB_LANGUAGE_KUI 541676875
#define FB_LANGUAGE_KULVI 541807947
#define FB_LANGUAGE_KUMAONI 542002507
#define FB_LANGUAGE_KUMYK 541939019
#define FB_LANGUAGE_KURDISH 542266699
#define FB_LANGUAGE_KURUKH 542463307
#define FB_LANGUAGE_KUY 542725451
#define FB_LANGUAGE_KWAKWALA 541808459
#define FB_LANGUAGE_KYRGYZ 542263627
#define FB_LANGUAGE_L_CREE 542262092
#define FB_LANGUAGE_LADAKHI 541803596
#define FB_LANGUAGE_LADIN 541344076
#define FB_LANGUAGE_LADINO 541349194
#define FB_LANGUAGE_LAHULI 541606220
#define FB_LANGUAGE_LAK 541802828
#define FB_LANGUAGE_LAKI 541674316
#define FB_LANGUAGE_LAMBANI 541933900
#define FB_LANGUAGE_LAMPUNG 542132812
#define FB_LANGUAGE_LAO 542064972
#define FB_LANGUAGE_LATIN 542392652
#define FB_LANGUAGE_LATVIAN 541677132
#define FB_LANGUAGE_LAZ 542785868
#define FB_LANGUAGE_LELEMI 541476172
#define FB_LANGUAGE_LEZGI 542786892
#define FB_LANGUAGE_LIGURIAN 541739340
#define FB_LANGUAGE_LIMBU 541216076
#define FB_LANGUAGE_LIMBURGISH 541935948
#define FB_LANGUAGE_LINGALA 542001484
#define FB_LANGUAGE_LIPO 542068812
#define FB_LANGUAGE_LISU 542329164
#define FB_LANGUAGE_LITHUANIAN 541611084
#define FB_LANGUAGE_LIV 542525772
#define FB_LANGUAGE_LOJBAN 542065226
#define FB_LANGUAGE_LOMA 541937484
#define FB_LANGUAGE_LOMBARD 542068044
#define FB_LANGUAGE_LOMWE 542592332
#define FB_LANGUAGE_LOW_MARI 541150540
#define FB_LANGUAGE_LOW_SAXON 542327886
#define FB_LANGUAGE_LOWER_SORBIAN 541217612
#define FB_LANGUAGE_LU 541344344
#define FB_LANGUAGE_LUBA_KATANGA 541218124
#define FB_LANGUAGE_LUBA_LULUA 541152588
#define FB_LANGUAGE_LULE_SAMI 541938508
#define FB_LANGUAGE_LUO 542070092
#define FB_LANGUAGE_LURI 541282892
#define FB_LANGUAGE_LUSHOOTSEED 542397772
#define FB_LANGUAGE_LUXEMBOURGISH 542790732
#define FB_LANGUAGE_LUYIA 541611340
#define FB_LANGUAGE_MACEDONIAN 541346637
#define FB_LANGUAGE_MADURA 541344077
#define FB_LANGUAGE_MAGAHI 541540685
#define FB_LANGUAGE_MAITHILI 541611085
#define FB_LANGUAGE_MAJANG 541737293
#define FB_LANGUAGE_MAKASAR 542264141
#define FB_LANGUAGE_MAKHUWA 541802829
#define FB_LANGUAGE_MAKONDE 541410379
#define FB_LANGUAGE_MALAGASY 541543501
#define FB_LANGUAGE_MALAY 542723149
#define FB_LANGUAGE_MALAYALAM 541868365
#define FB_LANGUAGE_MALAYALAM_REFORMED 542264397
#define FB_LANGUAGE_MALE 541412429
#define FB_LANGUAGE_MALINKE 542002253
#define FB_LANGUAGE_MALTESE 542331981
#define FB_LANGUAGE_MAM 541933901
#define FB_LANGUAGE_MANCHU 541606733
#define FB_LANGUAGE_MANDAR 542262349
#define FB_LANGUAGE_MANDINKA 541347405
#define FB_LANGUAGE_MANINKA 541806157
#define FB_LANGUAGE_MANIPURI 541675085
#define FB_LANGUAGE_MANO 542524749
#define FB_LANGUAGE_MANSI 541999437
#define FB_LANGUAGE_MANX 542658125
#define FB_LANGUAGE_MAORI 541676109
#define FB_LANGUAGE_MAPUDUNGUN 542130509
#define FB_LANGUAGE_MARATHI 542261581
#define FB_LANGUAGE_MARSHALLESE 541606221
#define FB_LANGUAGE_MARWARI 542589261
#define FB_LANGUAGE_MAYAN 542005581
#define FB_LANGUAGE_MAZANDERANI 542005837
#define FB_LANGUAGE_MBEMBE_TIGON 541153870
#define FB_LANGUAGE_MBO 542065229
#define FB_LANGUAGE_MBUNDU 541999693
#define FB_LANGUAGE_MEDUMBA 542529858
#define FB_LANGUAGE_MEEN 542000461
#define FB_LANGUAGE_MENDE 541410381
#define FB_LANGUAGE_MERU 542262605
#define FB_LANGUAGE_MEWATI 541938775
#define FB_LANGUAGE_MINANGKABAU 542001485
#define FB_LANGUAGE_MINJANGBAL 541215320
#define FB_LANGUAGE_MIRANDESE 541873997
#define FB_LANGUAGE_MIZO 542787917
#define FB_LANGUAGE_MOHAWK 541609805
#define FB_LANGUAGE_MOKSHA 541806413
#define FB_LANGUAGE_MOLDAVIAN 541871949
#define FB_LANGUAGE_MON 542003021
#define FB_LANGUAGE_MONGOLIAN 541544013
#define FB_LANGUAGE_MOOSE_CREE 542262093
#define FB_LANGUAGE_MORISYEN 541410893
#define FB_LANGUAGE_MOROCCAN 542265165
#define FB_LANGUAGE_MOSSI 542330957
#define FB_LANGUAGE_MUNDARI 542004557
#define FB_LANGUAGE_MUSCOGEE 542332237
#define FB_LANGUAGE_N_CREE 542262094
#define FB_LANGUAGE_NAGA_ASSAMESE 541540686
#define FB_LANGUAGE_NAGARI 542263118
#define FB_LANGUAGE_NAHUATL 541606222
#define FB_LANGUAGE_NANAI 541999438
#define FB_LANGUAGE_NASKAPI 542327118
#define FB_LANGUAGE_NAURUAN 542458190
#define FB_LANGUAGE_NAVAJO 542523726
#define FB_LANGUAGE_NDAU 541279310
#define FB_LANGUAGE_NDEBELE 541213774
#define FB_LANGUAGE_NDONGA 541541454
#define FB_LANGUAGE_NEAPOLITAN 542130510
#define FB_LANGUAGE_NEPALI 542131534
#define FB_LANGUAGE_NEWARI 542590286
#define FB_LANGUAGE_NGBAKA 541149006
#define FB_LANGUAGE_NIGERIAN_FULFULDE 542528838
#define FB_LANGUAGE_NIMADI 541413198
#define FB_LANGUAGE_NISI 542329166
#define FB_LANGUAGE_NIUEAN 542460238
#define FB_LANGUAGE_NKO 542067534
#define FB_LANGUAGE_NOGAI 541544270
#define FB_LANGUAGE_NORFOLK 541608272
#define FB_LANGUAGE_NORTH_SLAVEY 542327635
#define FB_LANGUAGE_NORTHERN_EMBERA 542133573
#define FB_LANGUAGE_NORTHERN_SAMI 541938510
#define FB_LANGUAGE_NORTHERN_SOTHO 542069582
#define FB_LANGUAGE_NORTHERN_TAI 541152334
#define FB_LANGUAGE_NORWAY_HOUSE_CREE 541280334
#define FB_LANGUAGE_NORWEGIAN 542265166
#define FB_LANGUAGE_NORWEGIAN_NYNORSK 542005582
#define FB_LANGUAGE_NOVIAL 542527310
#define FB_LANGUAGE_NUMANGGANG 542134094
#define FB_LANGUAGE_NUNAVIK_INUKTITUT 542461513
#define FB_LANGUAGE_NUU_CHAH_NULTH 541807950
#define FB_LANGUAGE_NYAMWEZI 541940046
#define FB_LANGUAGE_NYANKOLE 541870926
#define FB_LANGUAGE_OCCITAN 541672271
#define FB_LANGUAGE_ODIA 541676111
#define FB_LANGUAGE_OJI_CREE 542262095
#define FB_LANGUAGE_OJIBWAY 541215311
#define FB_LANGUAGE_OLD_IRISH 541149011
#define FB_LANGUAGE_OLD_JAVANESE 542589259
#define FB_LANGUAGE_ONEIDA 541412943
#define FB_LANGUAGE_ONONDAGA 542068303
#define FB_LANGUAGE_OROMO 542069327
#define FB_LANGUAGE_OSSETIAN 542331727
#define FB_LANGUAGE_PA_O_KAREN 541805634
#define FB_LANGUAGE_PALAUAN 542458192
#define FB_LANGUAGE_PALAUNG 541543504
#define FB_LANGUAGE_PALESTINIAN_ARAMAIC 541147472
#define FB_LANGUAGE_PALI 541868368
#define FB_LANGUAGE_PALPA 542130512
#define FB_LANGUAGE_PAMPANGAN 541933904
#define FB_LANGUAGE_PANGASINAN 541540688
#define FB_LANGUAGE_PAPIAMENTU 810565968
#define FB_LANGUAGE_PASHTO 542327120
#define FB_LANGUAGE_PATTANI_MALAY 541148749
#define FB_LANGUAGE_PENNSYLVANIA_GERMAN 541279312
#define FB_LANGUAGE_PERSIAN 542261574
#define FB_LANGUAGE_PHAKE 541805136
#define FB_LANGUAGE_PICARD 541344592
#define FB_LANGUAGE_PIEMONTESE 542330192
#define FB_LANGUAGE_PILAGA 541543504
#define FB_LANGUAGE_PITE_SAMI 541411923
#define FB_LANGUAGE_POCOMCHI 541609808
#define FB_LANGUAGE_POHNPEIAN 542003024
#define FB_LANGUAGE_POLISH 541805648
#define FB_LANGUAGE_POLYTONIC_GREEK 542263120
#define FB_LANGUAGE_PORTUGUESE 541545552
#define FB_LANGUAGE_PROVENCAL 542069328
#define FB_LANGUAGE_PUNJABI 541999440
#define FB_LANGUAGE_QUECHUA 542790993
#define FB_LANGUAGE_QUECHUA_BOLIVIA 541611345
#define FB_LANGUAGE_QUECHUA_ECUADOR 541677137
#define FB_LANGUAGE_QUECHUA_PERU 541611857
#define FB_LANGUAGE_R_CREE 542262098
#define FB_LANGUAGE_RAJASTHANI 541737298
#define FB_LANGUAGE_RAKHINE 541807169
#define FB_LANGUAGE_RAROTONGAN 542261586
#define FB_LANGUAGE_REJANG 541738322
#define FB_LANGUAGE_RIANG 541149522
#define FB_LANGUAGE_RIPUARIAN 541610827
#define FB_LANGUAGE_RITARUNGO 542394706
#define FB_LANGUAGE_ROHINGYA 541542482
#define FB_LANGUAGE_ROMANIAN 541937490
#define FB_LANGUAGE_ROMANSH 542330194
#define FB_LANGUAGE_ROMANY 542723922
#define FB_LANGUAGE_ROTUMAN 541938770
#define FB_LANGUAGE_RUNDI 542004562
#define FB_LANGUAGE_RUSSIAN 542332242
#define FB_LANGUAGE_RUSSIAN_BURIAT 542458450
#define FB_LANGUAGE_RUSYN 542724946
#define FB_LANGUAGE_SADRI 541344083
#define FB_LANGUAGE_SAKHA 541802841
#define FB_LANGUAGE_SAMOAN 542068051
#define FB_LANGUAGE_SAMOGITIAN 542328659
#define FB_LANGUAGE_SAN_BLAS_KUNA 541807939
#define FB_LANGUAGE_SANGO 542066515
#define FB_LANGUAGE_SANSKRIT 541999443
#define FB_LANGUAGE_SANTALI 542392659
#define FB_LANGUAGE_SARAIKI 541807187
#define FB_LANGUAGE_SARDINIAN 541348435
#define FB_LANGUAGE_SASAK 542327123
#define FB_LANGUAGE_SATERLAND_FRISIAN 542200915
#define FB_LANGUAGE_SAYISI 542720339
#define FB_LANGUAGE_SCOTS 541672275
#define FB_LANGUAGE_SCOTTISH_GAELIC 541409607
#define FB_LANGUAGE_SEKOTA 541738323
#define FB_LANGUAGE_SELKUP 541869395
#define FB_LANGUAGE_SENA 541150803
#define FB_LANGUAGE_SENECA 541410643
#define FB_LANGUAGE_SERBIAN 541217363
#define FB_LANGUAGE_SERER 542265939
#define FB_LANGUAGE_SGAW_KAREN 542593867
#define FB_LANGUAGE_SHAN 542001235
#define FB_LANGUAGE_SHONA 541150803
#define FB_LANGUAGE_SIBE 541215059
#define FB_LANGUAGE_SICILIAN 541999955
#define FB_LANGUAGE_SIDAMO 541346131
#define FB_LANGUAGE_SILESIAN 541874771
#define FB_LANGUAGE_SILTE_GURAGE 541542739
#define FB_LANGUAGE_SINDHI 541347411
#define FB_LANGUAGE_SINHALA 541609555
#define FB_LANGUAGE_SKOLT_SAMI 542329683
#define FB_LANGUAGE_SLAVEY 541150291
#define FB_LANGUAGE_SLOVAK 542722899
#define FB_LANGUAGE_SLOVENIAN 542526547
#define FB_LANGUAGE_SMALL_FLOWERY_MIAO 541935187
#define FB_LANGUAGE_SODO_GURAGE 541544275
#define FB_LANGUAGE_SOGA 541544280
#define FB_LANGUAGE_SOMALI 541871443
#define FB_LANGUAGE_SONGE 542134099
#define FB_LANGUAGE_SONINKE 541806163
#define FB_LANGUAGE_SOUTH_SLAVEY 541872979
#define FB_LANGUAGE_SOUTHERN_KIWAI 541346379
#define FB_LANGUAGE_SOUTHERN_SAMI 541938515
#define FB_LANGUAGE_SOUTHERN_SOTHO 542396243
#define FB_LANGUAGE_SPANISH 542135109
#define FB_LANGUAGE_STANDARD_MOROCCAN_TAMAZIGHT 541607770
#define FB_LANGUAGE_STRAITS_SALISH 542266451
#define FB_LANGUAGE_SUKUMA 541807955
#define FB_LANGUAGE_SUNDANESE 542004563
#define FB_LANGUAGE_SURI 542266707
#define FB_LANGUAGE_SUTU 542398547
#define FB_LANGUAGE_SVAN 541152851
#define FB_LANGUAGE_SWADAYA_ARAMAIC 541153107
#define FB_LANGUAGE_SWAHILI 541808467
#define FB_LANGUAGE_SWATI 542791507
#define FB_LANGUAGE_SWEDISH 541414995
#define FB_LANGUAGE_SYLHETI 541874515
#define FB_LANGUAGE_SYRIAC 542267731
#define FB_LANGUAGE_SYRIAC_EASTERN 1314019667
#define FB_LANGUAGE_SYRIAC_ESTRANGELA 1163024723
#define FB_LANGUAGE_SYRIAC_WESTERN 1246910803
#define FB_LANGUAGE_TABASARAN 541213012
#define FB_LANGUAGE_TACHELHIT 541673555
#define FB_LANGUAGE_TAGALOG 541869908
#define FB_LANGUAGE_TAHAGGART_TAMAHAQ 542525524
#define FB_LANGUAGE_TAHITIAN 542394452
#define FB_LANGUAGE_TAI_LAING 541870676
#define FB_LANGUAGE_TAJIKI 541737300
#define FB_LANGUAGE_TALYSH 542723156
#define FB_LANGUAGE_TAMASHEK 541609300
#define FB_LANGUAGE_TAMASHEQ 542196052
#define FB_LANGUAGE_TAMAZIGHT 541940308
#define FB_LANGUAGE_TAMIL 541933908
#define FB_LANGUAGE_TARIFIT 541477202
#define FB_LANGUAGE_TATAR 542392660
#define FB_LANGUAGE_TAWALLAMMAT_TAMAJAQ 542200916
#define FB_LANGUAGE_TAY 542792020
#define FB_LANGUAGE_TAYART_TAMAJEQ 542787668
#define FB_LANGUAGE_TELUGU 541869396
#define FB_LANGUAGE_TEMNE 542002516
#define FB_LANGUAGE_TETUM 542393684
#define FB_LANGUAGE_TH_CREE 542262100
#define FB_LANGUAGE_THAI 541149268
#define FB_LANGUAGE_THAILAND_MON 1414418253
#define FB_LANGUAGE_THOMPSON 542132308
#define FB_LANGUAGE_TIBETAN 541215060
#define FB_LANGUAGE_TIGRE 542263124
#define FB_LANGUAGE_TIGRINYA 542721876
#define FB_LANGUAGE_TIV 542525780
#define FB_LANGUAGE_TLINGIT 541674580
#define FB_LANGUAGE_TOBO 542523988
#define FB_LANGUAGE_TODO 541347668
#define FB_LANGUAGE_TOK_PISIN 541675604
#define FB_LANGUAGE_TOMA 809783124
#define FB_LANGUAGE_TONGA 541544020
#define FB_LANGUAGE_TONGAN 542000980
#define FB_LANGUAGE_TORKI 541219393
#define FB_LANGUAGE_TSHANGLA 541741908
#define FB_LANGUAGE_TSONGA 541545300
#define FB_LANGUAGE_TSWANA 541150804
#define FB_LANGUAGE_TULU 541873492
#define FB_LANGUAGE_TUMBUKA 541939028
#define FB_LANGUAGE_TUNDRA_ENETS 541412948
#define FB_LANGUAGE_TURKISH 541807188
#define FB_LANGUAGE_TURKMEN 541936468
#define FB_LANGUAGE_TUROYO_ARAMAIC 541152596
#define FB_LANGUAGE_TUSCARORA 542332244
#define FB_LANGUAGE_TUVALU 541873748
#define FB_LANGUAGE_TUVIN 542528852
#define FB_LANGUAGE_TWI 541677396
#define FB_LANGUAGE_TZOTZIL 542071380
#define FB_LANGUAGE_UDI 541672533
#define FB_LANGUAGE_UDMURT 541934677
#define FB_LANGUAGE_UKRAINIAN 542264149
#define FB_LANGUAGE_UMBUNDU 541216085
#define FB_LANGUAGE_UME_SAMI 542460499
#define FB_LANGUAGE_UPPER_SAXON 542464083
#define FB_LANGUAGE_UPPER_SORBIAN 541217621
#define FB_LANGUAGE_URALIC_PHONETIC 542134357
#define FB_LANGUAGE_URDU 541348437
#define FB_LANGUAGE_UYGHUR 541546837
#define FB_LANGUAGE_UZBEK 541219413
#define FB_LANGUAGE_VENDA 542000470
#define FB_LANGUAGE_VENETIAN 541279574
#define FB_LANGUAGE_VIETNAMESE 542394710
#define FB_LANGUAGE_VLAX_ROMANI 542723410
#define FB_LANGUAGE_VOLAPUK 541871958
#define FB_LANGUAGE_VORO 542069334
#define FB_LANGUAGE_WA 538984791
#define FB_LANGUAGE_WACI_GBE 541672279
#define FB_LANGUAGE_WAGDI 541540695
#define FB_LANGUAGE_WAKHI 541868631
#define FB_LANGUAGE_WALLOON 542002263
#define FB_LANGUAGE_WARAY_WARAY 542261591
#define FB_LANGUAGE_WAYANAD_CHETTI 542397507
#define FB_LANGUAGE_WAYUU 541283655
#define FB_LANGUAGE_WELSH 541869399
#define FB_LANGUAGE_WENDAT 542393431
#define FB_LANGUAGE_WEST_CREE 542262103
#define FB_LANGUAGE_WESTERN_CHAM 541149763
#define FB_LANGUAGE_WESTERN_KAYAH 542464331
#define FB_LANGUAGE_WESTERN_PANJABI 541216336
#define FB_LANGUAGE_WESTERN_PWO_KAREN 542070608
#define FB_LANGUAGE_WOLOF 541477975
#define FB_LANGUAGE_WOODS_CREE 542262084
#define FB_LANGUAGE_WUDING_LUQUAN_YI 542201689
#define FB_LANGUAGE_WYANDOT 542005591
#define FB_LANGUAGE_XHOSA 542328920
#define FB_LANGUAGE_Y_CREE 542262105
#define FB_LANGUAGE_YAO 542064985
#define FB_LANGUAGE_YAPESE 542130521
#define FB_LANGUAGE_YI_CLASSIC 541280601
#define FB_LANGUAGE_YI_MODERN 541935961
#define FB_LANGUAGE_YIDDISH 541673802
#define FB_LANGUAGE_YORUBA 541147737
#define FB_LANGUAGE_ZAMBOANGA_CHAVACANO 541803075
#define FB_LANGUAGE_ZANDE 541347418
#define FB_LANGUAGE_ZARMA 542263876
#define FB_LANGUAGE_ZAZAKI 541153882
#define FB_LANGUAGE_ZEALANDIC 541148506
#define FB_LANGUAGE_ZHUANG 541149274
#define FB_LANGUAGE_ZULU 541873498

typedef uint32_t fb_Text_Direction;
#define FB_TEXT_DIRECTION_DONT_KNOW 0
#define FB_TEXT_DIRECTION_LEFT_TO_RIGHT 1
#define FB_TEXT_DIRECTION_RIGHT_TO_LEFT 2

typedef struct fb_Line_Height fb_Line_Height;
typedef uint8_t fb_Line_Height_Kind;
#define FB_LINE_HEIGHT_KIND_PERCENTAGE 0
#define FB_LINE_HEIGHT_KIND_FIXED 1

struct fb_Line_Height {
    fb_Line_Height_Kind kind;
    union {
    float percentage;
    float fixed;
    };
};
_Static_assert(sizeof(fb_Line_Height) == 8, "fb_Line_Height");
_Static_assert(offsetof(fb_Line_Height, kind) == 0, "fb_Line_Height.kind");

typedef uint8_t fb_Text_Wrapping;
#define FB_TEXT_WRAPPING_WORD 0
#define FB_TEXT_WRAPPING_CHARACTER 1
#define FB_TEXT_WRAPPING_NONE 2

typedef uint8_t fb_Cursor;
#define FB_CURSOR_DEFAULT 0
#define FB_CURSOR_TEXT 1
#define FB_CURSOR_POINTER 2
#define FB_CURSOR_WAIT 3
#define FB_CURSOR_PROGRESS 4
#define FB_CURSOR_CROSSHAIR 5
#define FB_CURSOR_HELP 6
#define FB_CURSOR_NOT_ALLOWED 7
#define FB_CURSOR_MOVE 8
#define FB_CURSOR_EW_RESIZE 9
#define FB_CURSOR_NS_RESIZE 10
#define FB_CURSOR_NWSE_RESIZE 11
#define FB_CURSOR_NESW_RESIZE 12

typedef uint8_t fb_Overflow;
#define FB_OVERFLOW_VISIBLE 0
#define FB_OVERFLOW_WRAP 1

typedef struct fb_Placement fb_Placement;
typedef uint8_t fb_Placement_Kind;
#define FB_PLACEMENT_KIND_FLOW 0
#define FB_PLACEMENT_KIND_FIXED 1
#define FB_PLACEMENT_KIND_RELATIVE 2

typedef uint8_t fb_Corner;
#define FB_CORNER_TOP_LEFT 0
#define FB_CORNER_TOP_RIGHT 1
#define FB_CORNER_BOTTOM_LEFT 2
#define FB_CORNER_BOTTOM_RIGHT 3

struct fb_Placement {
    fb_Placement_Kind kind;
    fb_Corner corner;
    union {
    fb_Vector2 fixed;
    fb_Vector2 relative;
    };
};
_Static_assert(sizeof(fb_Placement) == 12, "fb_Placement");
_Static_assert(offsetof(fb_Placement, kind) == 0, "fb_Placement.kind");
_Static_assert(offsetof(fb_Placement, corner) == 1, "fb_Placement.corner");

typedef struct fb_Sizing fb_Sizing;
typedef uint8_t fb_Sizing_Kind;
#define FB_SIZING_KIND_FIT 0
#define FB_SIZING_KIND_FIXED 1
#define FB_SIZING_KIND_GROW 2

struct fb_Sizing {
    fb_Sizing_Kind kind;
    union {
    float fixed;
    float ratio;
    float grow;
    };
};
_Static_assert(sizeof(fb_Sizing) == 8, "fb_Sizing");
_Static_assert(offsetof(fb_Sizing, kind) == 0, "fb_Sizing.kind");

typedef uint8_t fb_Direction;
#define FB_DIRECTION_HORIZONTAL 0
#define FB_DIRECTION_VERTICAL 1

typedef uint8_t fb_Alignment;
#define FB_ALIGNMENT_START 0
#define FB_ALIGNMENT_CENTER 1
#define FB_ALIGNMENT_END 2

struct fb_Complete_Style {
    fb_Background background;
    fb_Vector4 color;
    float border_radius;
    fb_Vector4 border_color;
    fb_Sides border_width;
    fb_Border_Style border_style;
    fb_Shadow shadow;
    fb_Font * font;
    fb_Language language;
    fb_Text_Direction text_direction;
    uint16_t font_weight;
    float font_size;
    fb_Line_Height line_height;
    fb_Text_Wrapping text_wrapping;
    fb_Cursor cursor;
    fb_Overflow overflow;
    fb_Placement placement;
    uint16_t z_index;
    float min_width;
    float max_width;
    fb_Sizing width;
    float max_height;
    float min_height;
    fb_Sizing height;
    fb_Vector2 translate;
    fb_Vector2 children_offset;
    fb_Sides padding;
    fb_Sides margin;
    fb_Direction direction;
    fb_Alignment x_justification;
    fb_Alignment y_justification;
};
_Static_assert(sizeof(fb_Complete_Style) == 264, "fb_Complete_Style");
_Static_assert(offsetof(fb_Complete_Style, background) == 0, "fb_Complete_Style.background");
_Static_assert(offsetof(fb_Complete_Style, color) == 32, "fb_Complete_Style.color");
_Static_assert(offsetof(fb_Complete_Style, border_radius) == 48, "fb_Complete_Style.border_radius");
_Static_assert(offsetof(fb_Complete_Style, border_color) == 52, "fb_Complete_Style.border_color");
_Static_assert(offsetof(fb_Complete_Style, border_width) == 68, "fb_Complete_Style.border_width");
_Static_assert(offsetof(fb_Complete_Style, border_style) == 84, "fb_Complete_Style.border_style");
_Static_assert(offsetof(fb_Complete_Style, shadow) == 88, "fb_Complete_Style.shadow");
_Static_assert(offsetof(fb_Complete_Style, font) == 128, "fb_Complete_Style.font");
_Static_assert(offsetof(fb_Complete_Style, language) == 136, "fb_Complete_Style.language");
_Static_assert(offsetof(fb_Complete_Style, text_direction) == 140, "fb_Complete_Style.text_direction");
_Static_assert(offsetof(fb_Complete_Style, font_weight) == 144, "fb_Complete_Style.font_weight");
_Static_assert(offsetof(fb_Complete_Style, font_size) == 148, "fb_Complete_Style.font_size");
_Static_assert(offsetof(fb_Complete_Style, line_height) == 152, "fb_Complete_Style.line_height");
_Static_assert(offsetof(fb_Complete_Style, text_wrapping) == 160, "fb_Complete_Style.text_wrapping");
_Static_assert(offsetof(fb_Complete_Style, cursor) == 161, "fb_Complete_Style.cursor");
_Static_assert(offsetof(fb_Complete_Style, overflow) == 162, "fb_Complete_Style.overflow");
_Static_assert(offsetof(fb_Complete_Style, placement) == 164, "fb_Complete_Style.placement");
_Static_assert(offsetof(fb_Complete_Style, z_index) == 176, "fb_Complete_Style.z_index");
_Static_assert(offsetof(fb_Complete_Style, min_width) == 180, "fb_Complete_Style.min_width");
_Static_assert(offsetof(fb_Complete_Style, max_width) == 184, "fb_Complete_Style.max_width");
_Static_assert(offsetof(fb_Complete_Style, width) == 188, "fb_Complete_Style.width");
_Static_assert(offsetof(fb_Complete_Style, max_height) == 196, "fb_Complete_Style.max_height");
_Static_assert(offsetof(fb_Complete_Style, min_height) == 200, "fb_Complete_Style.min_height");
_Static_assert(offsetof(fb_Complete_Style, height) == 204, "fb_Complete_Style.height");
_Static_assert(offsetof(fb_Complete_Style, translate) == 212, "fb_Complete_Style.translate");
_Static_assert(offsetof(fb_Complete_Style, children_offset) == 220, "fb_Complete_Style.children_offset");
_Static_assert(offsetof(fb_Complete_Style, padding) == 228, "fb_Complete_Style.padding");
_Static_assert(offsetof(fb_Complete_Style, margin) == 244, "fb_Complete_Style.margin");
_Static_assert(offsetof(fb_Complete_Style, direction) == 260, "fb_Complete_Style.direction");
_Static_assert(offsetof(fb_Complete_Style, x_justification) == 261, "fb_Complete_Style.x_justification");
_Static_assert(offsetof(fb_Complete_Style, y_justification) == 262, "fb_Complete_Style.y_justification");

typedef struct fb_Base_Style fb_Base_Style;
struct fb_Base_Style {
    fb_Font * font;
    fb_Language language;
    fb_Text_Direction text_direction;
    fb_Vector4 color;
    float font_size;
    uint16_t font_weight;
    fb_Line_Height line_height;
    fb_Text_Wrapping text_wrapping;
    fb_Cursor cursor;
};
_Static_assert(sizeof(fb_Base_Style) == 56, "fb_Base_Style");
_Static_assert(offsetof(fb_Base_Style, font) == 0, "fb_Base_Style.font");
_Static_assert(offsetof(fb_Base_Style, language) == 8, "fb_Base_Style.language");
_Static_assert(offsetof(fb_Base_Style, text_direction) == 12, "fb_Base_Style.text_direction");
_Static_assert(offsetof(fb_Base_Style, color) == 16, "fb_Base_Style.color");
_Static_assert(offsetof(fb_Base_Style, font_size) == 32, "fb_Base_Style.font_size");
_Static_assert(offsetof(fb_Base_Style, font_weight) == 36, "fb_Base_Style.font_weight");
_Static_assert(offsetof(fb_Base_Style, line_height) == 40, "fb_Base_Style.line_height");
_Static_assert(offsetof(fb_Base_Style, text_wrapping) == 48, "fb_Base_Style.text_wrapping");
_Static_assert(offsetof(fb_Base_Style, cursor) == 49, "fb_Base_Style.cursor");

typedef struct fb_Style fb_Style;
struct fb_Style {
    fb_Background background;
    fb_Vector4 color;
    float border_radius;
    fb_Vector4 border_color;
    fb_Sides border_width;
    fb_Border_Style border_style;
    fb_Shadow shadow;
    fb_Font * font;
    uint16_t font_weight;
    float font_size;
    fb_Line_Height line_height;
    fb_Text_Wrapping text_wrapping;
    fb_Language language;
    fb_Text_Direction text_direction;
    fb_Cursor cursor;
    fb_Overflow overflow;
    fb_Placement placement;
    uint16_t z_index;
    float min_width;
    float max_width;
    fb_Sizing width;
    float min_height;
    float max_height;
    fb_Sizing height;
    fb_Vector2 translate;
    fb_Vector2 children_offset;
    fb_Sides padding;
    fb_Sides margin;
    fb_Alignment x_justification;
    fb_Alignment y_justification;
    fb_Direction direction;
};
_Static_assert(sizeof(fb_Style) == 272, "fb_Style");
_Static_assert(offsetof(fb_Style, background) == 0, "fb_Style.background");
_Static_assert(offsetof(fb_Style, color) == 32, "fb_Style.color");
_Static_assert(offsetof(fb_Style, border_radius) == 48, "fb_Style.border_radius");
_Static_assert(offsetof(fb_Style, border_color) == 52, "fb_Style.border_color");
_Static_assert(offsetof(fb_Style, border_width) == 68, "fb_Style.border_width");
_Static_assert(offsetof(fb_Style, border_style) == 84, "fb_Style.border_style");
_Static_assert(offsetof(fb_Style, shadow) == 88, "fb_Style.shadow");
_Static_assert(offsetof(fb_Style, font) == 128, "fb_Style.font");
_Static_assert(offsetof(fb_Style, font_weight) == 136, "fb_Style.font_weight");
_Static_assert(offsetof(fb_Style, font_size) == 140, "fb_Style.font_size");
_Static_assert(offsetof(fb_Style, line_height) == 144, "fb_Style.line_height");
_Static_assert(offsetof(fb_Style, text_wrapping) == 152, "fb_Style.text_wrapping");
_Static_assert(offsetof(fb_Style, language) == 156, "fb_Style.language");
_Static_assert(offsetof(fb_Style, text_direction) == 160, "fb_Style.text_direction");
_Static_assert(offsetof(fb_Style, cursor) == 164, "fb_Style.cursor");
_Static_assert(offsetof(fb_Style, overflow) == 165, "fb_Style.overflow");
_Static_assert(offsetof(fb_Style, placement) == 168, "fb_Style.placement");
_Static_assert(offsetof(fb_Style, z_index) == 180, "fb_Style.z_index");
_Static_assert(offsetof(fb_Style, min_width) == 184, "fb_Style.min_width");
_Static_assert(offsetof(fb_Style, max_width) == 188, "fb_Style.max_width");
_Static_assert(offsetof(fb_Style, width) == 192, "fb_Style.width");
_Static_assert(offsetof(fb_Style, min_height) == 200, "fb_Style.min_height");
_Static_assert(offsetof(fb_Style, max_height) == 204, "fb_Style.max_height");
_Static_assert(offsetof(fb_Style, height) == 208, "fb_Style.height");
_Static_assert(offsetof(fb_Style, translate) == 216, "fb_Style.translate");
_Static_assert(offsetof(fb_Style, children_offset) == 224, "fb_Style.children_offset");
_Static_assert(offsetof(fb_Style, padding) == 232, "fb_Style.padding");
_Static_assert(offsetof(fb_Style, margin) == 248, "fb_Style.margin");
_Static_assert(offsetof(fb_Style, x_justification) == 264, "fb_Style.x_justification");
_Static_assert(offsetof(fb_Style, y_justification) == 265, "fb_Style.y_justification");
_Static_assert(offsetof(fb_Style, direction) == 266, "fb_Style.direction");

typedef struct fb_Node_Opening_Data fb_Node_Opening_Data;
struct fb_Node_Opening_Data {
    int64_t parent_index;
    uint64_t scope_key;
    fb_Base_Style base_style;
    int64_t node_index;
};
_Static_assert(sizeof(fb_Node_Opening_Data) == 80, "fb_Node_Opening_Data");
_Static_assert(offsetof(fb_Node_Opening_Data, parent_index) == 0, "fb_Node_Opening_Data.parent_index");
_Static_assert(offsetof(fb_Node_Opening_Data, scope_key) == 8, "fb_Node_Opening_Data.scope_key");
_Static_assert(offsetof(fb_Node_Opening_Data, base_style) == 16, "fb_Node_Opening_Data.base_style");
_Static_assert(offsetof(fb_Node_Opening_Data, node_index) == 72, "fb_Node_Opening_Data.node_index");

typedef struct fb_Forbear fb_Forbear;
typedef struct fb_Node fb_Node;
typedef int64_t fb_Node_Kind;
#define FB_NODE_KIND_ELEMENT 0
#define FB_NODE_KIND_SCOPE 1

typedef struct fb_Glyphs fb_Glyphs;
typedef struct fb_Glyph fb_Glyph;
typedef struct fb_kbts_encode_utf8 fb_kbts_encode_utf8;
struct fb_kbts_encode_utf8 {
    uint8_t Encoded[4];
    int32_t EncodedLength;
    int32_t Valid;
};
_Static_assert(sizeof(fb_kbts_encode_utf8) == 12, "fb_kbts_encode_utf8");
_Static_assert(offsetof(fb_kbts_encode_utf8, Encoded) == 0, "fb_kbts_encode_utf8.Encoded");
_Static_assert(offsetof(fb_kbts_encode_utf8, EncodedLength) == 4, "fb_kbts_encode_utf8.EncodedLength");
_Static_assert(offsetof(fb_kbts_encode_utf8, Valid) == 8, "fb_kbts_encode_utf8.Valid");

struct fb_Glyph {
    int32_t index;
    int64_t index_into_original_text;
    fb_kbts_encode_utf8 utf8;
    _Bool starts_word;
    _Bool can_wrap_before;
    fb_Vector2 position;
    fb_Vector2 advance;
    fb_Vector2 offset;
};
_Static_assert(sizeof(fb_Glyph) == 56, "fb_Glyph");
_Static_assert(offsetof(fb_Glyph, index) == 0, "fb_Glyph.index");
_Static_assert(offsetof(fb_Glyph, index_into_original_text) == 8, "fb_Glyph.index_into_original_text");
_Static_assert(offsetof(fb_Glyph, utf8) == 16, "fb_Glyph.utf8");
_Static_assert(offsetof(fb_Glyph, starts_word) == 28, "fb_Glyph.starts_word");
_Static_assert(offsetof(fb_Glyph, can_wrap_before) == 29, "fb_Glyph.can_wrap_before");
_Static_assert(offsetof(fb_Glyph, position) == 32, "fb_Glyph.position");
_Static_assert(offsetof(fb_Glyph, advance) == 40, "fb_Glyph.advance");
_Static_assert(offsetof(fb_Glyph, offset) == 48, "fb_Glyph.offset");

typedef struct fb_Allocator fb_Allocator;
struct fb_Allocator {
    _Alignas(8) uint8_t proc[8];
    void * data;
};
_Static_assert(sizeof(fb_Allocator) == 16, "fb_Allocator");
_Static_assert(offsetof(fb_Allocator, proc) == 0, "fb_Allocator.proc");
_Static_assert(offsetof(fb_Allocator, data) == 8, "fb_Allocator.data");

typedef struct { int64_t count; fb_Glyph *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Glyph;

typedef struct { int64_t count; int64_t *data; int64_t allocated; fb_Allocator allocator; } fb_Array_int64_t;

struct fb_Glyphs {
    uint64_t hash;
    int32_t length;
    fb_Array_Glyph array;
    fb_Array_int64_t pre_break_indices;
    float ascent;
    float line_height;
    fb_Vector2 min_size;
    fb_Vector2 max_size;
};
_Static_assert(sizeof(fb_Glyphs) == 120, "fb_Glyphs");
_Static_assert(offsetof(fb_Glyphs, hash) == 0, "fb_Glyphs.hash");
_Static_assert(offsetof(fb_Glyphs, length) == 8, "fb_Glyphs.length");
_Static_assert(offsetof(fb_Glyphs, array) == 16, "fb_Glyphs.array");
_Static_assert(offsetof(fb_Glyphs, pre_break_indices) == 56, "fb_Glyphs.pre_break_indices");
_Static_assert(offsetof(fb_Glyphs, ascent) == 96, "fb_Glyphs.ascent");
_Static_assert(offsetof(fb_Glyphs, line_height) == 100, "fb_Glyphs.line_height");
_Static_assert(offsetof(fb_Glyphs, min_size) == 104, "fb_Glyphs.min_size");
_Static_assert(offsetof(fb_Glyphs, max_size) == 112, "fb_Glyphs.max_size");

struct fb_Node {
    fb_Node_Kind kind;
    fb_Vector2 size;
    fb_Vector2 position;
    fb_Vector2 min_size;
    fb_Vector2 max_size;
    uint16_t z;
    int64_t first_child;
    int64_t last_child;
    int64_t next_sibling;
    int64_t previous_sibling;
    int64_t parent;
    fb_Glyphs glyphs;
    fb_Complete_Style style;
    fb_Vector2 content_size;
    fb_Vector4 clipping_rectangle;
    int64_t state_offset;
    int64_t state_size;
    int64_t pool_slot;
    uint64_t key;
    void * tree;
};
_Static_assert(sizeof(fb_Node) == 536, "fb_Node");
_Static_assert(offsetof(fb_Node, kind) == 0, "fb_Node.kind");
_Static_assert(offsetof(fb_Node, size) == 8, "fb_Node.size");
_Static_assert(offsetof(fb_Node, position) == 16, "fb_Node.position");
_Static_assert(offsetof(fb_Node, min_size) == 24, "fb_Node.min_size");
_Static_assert(offsetof(fb_Node, max_size) == 32, "fb_Node.max_size");
_Static_assert(offsetof(fb_Node, z) == 40, "fb_Node.z");
_Static_assert(offsetof(fb_Node, first_child) == 48, "fb_Node.first_child");
_Static_assert(offsetof(fb_Node, last_child) == 56, "fb_Node.last_child");
_Static_assert(offsetof(fb_Node, next_sibling) == 64, "fb_Node.next_sibling");
_Static_assert(offsetof(fb_Node, previous_sibling) == 72, "fb_Node.previous_sibling");
_Static_assert(offsetof(fb_Node, parent) == 80, "fb_Node.parent");
_Static_assert(offsetof(fb_Node, glyphs) == 88, "fb_Node.glyphs");
_Static_assert(offsetof(fb_Node, style) == 208, "fb_Node.style");
_Static_assert(offsetof(fb_Node, content_size) == 472, "fb_Node.content_size");
_Static_assert(offsetof(fb_Node, clipping_rectangle) == 480, "fb_Node.clipping_rectangle");
_Static_assert(offsetof(fb_Node, state_offset) == 496, "fb_Node.state_offset");
_Static_assert(offsetof(fb_Node, state_size) == 504, "fb_Node.state_size");
_Static_assert(offsetof(fb_Node, pool_slot) == 512, "fb_Node.pool_slot");
_Static_assert(offsetof(fb_Node, key) == 520, "fb_Node.key");
_Static_assert(offsetof(fb_Node, tree) == 528, "fb_Node.tree");

typedef struct { int64_t count; fb_Node *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Node;

typedef struct fb_Node_Measurement fb_Node_Measurement;
struct fb_Node_Measurement {
    fb_Vector2 size;
    fb_Vector2 content_size;
    fb_Vector2 position;
    fb_Vector4 clipping_rectangle;
    int64_t state_offset;
    int64_t state_size;
    int64_t pool_slot;
    uint64_t key;
};
_Static_assert(sizeof(fb_Node_Measurement) == 72, "fb_Node_Measurement");
_Static_assert(offsetof(fb_Node_Measurement, size) == 0, "fb_Node_Measurement.size");
_Static_assert(offsetof(fb_Node_Measurement, content_size) == 8, "fb_Node_Measurement.content_size");
_Static_assert(offsetof(fb_Node_Measurement, position) == 16, "fb_Node_Measurement.position");
_Static_assert(offsetof(fb_Node_Measurement, clipping_rectangle) == 24, "fb_Node_Measurement.clipping_rectangle");
_Static_assert(offsetof(fb_Node_Measurement, state_offset) == 40, "fb_Node_Measurement.state_offset");
_Static_assert(offsetof(fb_Node_Measurement, state_size) == 48, "fb_Node_Measurement.state_size");
_Static_assert(offsetof(fb_Node_Measurement, pool_slot) == 56, "fb_Node_Measurement.pool_slot");
_Static_assert(offsetof(fb_Node_Measurement, key) == 64, "fb_Node_Measurement.key");

typedef struct { int64_t count; fb_Node_Measurement *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Node_Measurement;

typedef struct fb_Pool_Slot fb_Pool_Slot;
struct fb_Pool_Slot {
    _Alignas(8) uint8_t pool[40];
    fb_Allocator allocator;
    int64_t last_frame;
    _Bool used;
};
_Static_assert(sizeof(fb_Pool_Slot) == 72, "fb_Pool_Slot");
_Static_assert(offsetof(fb_Pool_Slot, pool) == 0, "fb_Pool_Slot.pool");
_Static_assert(offsetof(fb_Pool_Slot, allocator) == 40, "fb_Pool_Slot.allocator");
_Static_assert(offsetof(fb_Pool_Slot, last_frame) == 56, "fb_Pool_Slot.last_frame");
_Static_assert(offsetof(fb_Pool_Slot, used) == 64, "fb_Pool_Slot.used");

typedef struct fb_Glyph_Atlas fb_Glyph_Atlas;
struct fb_Glyph_Atlas {
    uint32_t texture;
    _Alignas(8) uint8_t table[56];
    int32_t cursor_x;
    int32_t cursor_y;
    int32_t row_height;
    int32_t size;
    double scale;
};
_Static_assert(sizeof(fb_Glyph_Atlas) == 88, "fb_Glyph_Atlas");
_Static_assert(offsetof(fb_Glyph_Atlas, texture) == 0, "fb_Glyph_Atlas.texture");
_Static_assert(offsetof(fb_Glyph_Atlas, table) == 8, "fb_Glyph_Atlas.table");
_Static_assert(offsetof(fb_Glyph_Atlas, cursor_x) == 64, "fb_Glyph_Atlas.cursor_x");
_Static_assert(offsetof(fb_Glyph_Atlas, cursor_y) == 68, "fb_Glyph_Atlas.cursor_y");
_Static_assert(offsetof(fb_Glyph_Atlas, row_height) == 72, "fb_Glyph_Atlas.row_height");
_Static_assert(offsetof(fb_Glyph_Atlas, size) == 76, "fb_Glyph_Atlas.size");
_Static_assert(offsetof(fb_Glyph_Atlas, scale) == 80, "fb_Glyph_Atlas.scale");

typedef struct fb_Windows_GL_Window fb_Windows_GL_Window;
typedef struct fb_Windows_GL_Backend fb_Windows_GL_Backend;
struct fb_Windows_GL_Backend {
    int64_t (*message)(void *, fb_Windows_GL_Window *, void *, uint32_t, uint64_t, int64_t, _Bool *);
    void * message_data;
    void * wndproc_context;
    void * cursors[13];
    void (*render)(void *);
    void * render_data;
    uint32_t clipboard_sequence;
    fb_String clipboard_text_buffer;
    fb_String clipboard_text;
};
_Static_assert(sizeof(fb_Windows_GL_Backend) == 184, "fb_Windows_GL_Backend");
_Static_assert(offsetof(fb_Windows_GL_Backend, message) == 0, "fb_Windows_GL_Backend.message");
_Static_assert(offsetof(fb_Windows_GL_Backend, message_data) == 8, "fb_Windows_GL_Backend.message_data");
_Static_assert(offsetof(fb_Windows_GL_Backend, wndproc_context) == 16, "fb_Windows_GL_Backend.wndproc_context");
_Static_assert(offsetof(fb_Windows_GL_Backend, cursors) == 24, "fb_Windows_GL_Backend.cursors");
_Static_assert(offsetof(fb_Windows_GL_Backend, render) == 128, "fb_Windows_GL_Backend.render");
_Static_assert(offsetof(fb_Windows_GL_Backend, render_data) == 136, "fb_Windows_GL_Backend.render_data");
_Static_assert(offsetof(fb_Windows_GL_Backend, clipboard_sequence) == 144, "fb_Windows_GL_Backend.clipboard_sequence");
_Static_assert(offsetof(fb_Windows_GL_Backend, clipboard_text_buffer) == 152, "fb_Windows_GL_Backend.clipboard_text_buffer");
_Static_assert(offsetof(fb_Windows_GL_Backend, clipboard_text) == 168, "fb_Windows_GL_Backend.clipboard_text");

typedef uint32_t fb_Preferred_Theme;
#define FB_PREFERRED_THEME_DARK 0
#define FB_PREFERRED_THEME_LIGHT 1

typedef struct fb_Keyboard_State fb_Keyboard_State;
typedef struct fb_Key_Event fb_Key_Event;
typedef int64_t fb_Key_Event_Kind;
#define FB_KEY_EVENT_KIND_REPEATED 0
#define FB_KEY_EVENT_KIND_RELEASED 1
#define FB_KEY_EVENT_KIND_PRESSED 2

typedef uint32_t fb_Key;
#define FB_KEY_A 97
#define FB_KEY_B 98
#define FB_KEY_C 99
#define FB_KEY_D 100
#define FB_KEY_E 101
#define FB_KEY_F 102
#define FB_KEY_G 103
#define FB_KEY_H 104
#define FB_KEY_I 105
#define FB_KEY_J 106
#define FB_KEY_K 107
#define FB_KEY_L 108
#define FB_KEY_M 109
#define FB_KEY_N 110
#define FB_KEY_O 111
#define FB_KEY_P 112
#define FB_KEY_Q 113
#define FB_KEY_R 114
#define FB_KEY_S 115
#define FB_KEY_T 116
#define FB_KEY_U 117
#define FB_KEY_V 118
#define FB_KEY_W 119
#define FB_KEY_X 120
#define FB_KEY_Y 121
#define FB_KEY_Z 122
#define FB_KEY_DIGIT_0 48
#define FB_KEY_DIGIT_1 49
#define FB_KEY_DIGIT_2 50
#define FB_KEY_DIGIT_3 51
#define FB_KEY_DIGIT_4 52
#define FB_KEY_DIGIT_5 53
#define FB_KEY_DIGIT_6 54
#define FB_KEY_DIGIT_7 55
#define FB_KEY_DIGIT_8 56
#define FB_KEY_DIGIT_9 57
#define FB_KEY_SPACE 32
#define FB_KEY_EXCLAMATION 33
#define FB_KEY_QUOTE 34
#define FB_KEY_HASH 35
#define FB_KEY_DOLLAR 36
#define FB_KEY_PERCENT 37
#define FB_KEY_AMPERSAND 38
#define FB_KEY_APOSTROPHE 39
#define FB_KEY_PARENTHESIS_LEFT 40
#define FB_KEY_PARENTHESIS_RIGHT 41
#define FB_KEY_ASTERISK 42
#define FB_KEY_PLUS 43
#define FB_KEY_COMMA 44
#define FB_KEY_MINUS 45
#define FB_KEY_PERIOD 46
#define FB_KEY_SLASH 47
#define FB_KEY_COLON 58
#define FB_KEY_SEMICOLON 59
#define FB_KEY_LESS 60
#define FB_KEY_EQUAL 61
#define FB_KEY_GREATER 62
#define FB_KEY_QUESTION 63
#define FB_KEY_AT 64
#define FB_KEY_BRACKET_LEFT 91
#define FB_KEY_BACKSLASH 92
#define FB_KEY_BRACKET_RIGHT 93
#define FB_KEY_CARET 94
#define FB_KEY_UNDERSCORE 95
#define FB_KEY_GRAVE 96
#define FB_KEY_BRACE_LEFT 123
#define FB_KEY_PIPE 124
#define FB_KEY_BRACE_RIGHT 125
#define FB_KEY_TILDE 126
#define FB_KEY_ESCAPE 1114112
#define FB_KEY_ENTER 1114113
#define FB_KEY_TAB 1114114
#define FB_KEY_BACKSPACE 1114115
#define FB_KEY_DELETE 1114116
#define FB_KEY_INSERT 1114117
#define FB_KEY_ARROW_LEFT 1114118
#define FB_KEY_ARROW_RIGHT 1114119
#define FB_KEY_ARROW_UP 1114120
#define FB_KEY_ARROW_DOWN 1114121
#define FB_KEY_HOME 1114122
#define FB_KEY_END 1114123
#define FB_KEY_PAGE_UP 1114124
#define FB_KEY_PAGE_DOWN 1114125
#define FB_KEY_F1 1114126
#define FB_KEY_F2 1114127
#define FB_KEY_F3 1114128
#define FB_KEY_F4 1114129
#define FB_KEY_F5 1114130
#define FB_KEY_F6 1114131
#define FB_KEY_F7 1114132
#define FB_KEY_F8 1114133
#define FB_KEY_F9 1114134
#define FB_KEY_F10 1114135
#define FB_KEY_F11 1114136
#define FB_KEY_F12 1114137
#define FB_KEY_F13 1114138
#define FB_KEY_F14 1114139
#define FB_KEY_F15 1114140
#define FB_KEY_F16 1114141
#define FB_KEY_F17 1114142
#define FB_KEY_F18 1114143
#define FB_KEY_F19 1114144
#define FB_KEY_F20 1114145
#define FB_KEY_SHIFT_LEFT 1114146
#define FB_KEY_SHIFT_RIGHT 1114147
#define FB_KEY_CONTROL_LEFT 1114148
#define FB_KEY_CONTROL_RIGHT 1114149
#define FB_KEY_ALT_LEFT 1114150
#define FB_KEY_ALT_RIGHT 1114151
#define FB_KEY_SUPER_LEFT 1114152
#define FB_KEY_SUPER_RIGHT 1114153
#define FB_KEY_CAPS_LOCK 1114154
#define FB_KEY_FUNCTION 1114155
#define FB_KEY_VOLUME_UP 1114156
#define FB_KEY_VOLUME_DOWN 1114157
#define FB_KEY_VOLUME_MUTE 1114158
#define FB_KEY_CONTEXT_MENU 1114159
#define FB_KEY_HELP 1114160

struct fb_Key_Event {
    fb_Key_Event_Kind kind;
    fb_Key key;
};
_Static_assert(sizeof(fb_Key_Event) == 16, "fb_Key_Event");
_Static_assert(offsetof(fb_Key_Event, kind) == 0, "fb_Key_Event.kind");
_Static_assert(offsetof(fb_Key_Event, key) == 8, "fb_Key_Event.key");

typedef struct { int64_t count; fb_Key_Event *data; } fb_View_Key_Event;

struct fb_Keyboard_State {
    uint16_t high_surrogate;
    fb_Key_Event events_buffer[96];
    fb_View_Key_Event events;
    fb_Key held[776];
    _Bool simulated;
};
_Static_assert(sizeof(fb_Keyboard_State) == 4672, "fb_Keyboard_State");
_Static_assert(offsetof(fb_Keyboard_State, high_surrogate) == 0, "fb_Keyboard_State.high_surrogate");
_Static_assert(offsetof(fb_Keyboard_State, events_buffer) == 8, "fb_Keyboard_State.events_buffer");
_Static_assert(offsetof(fb_Keyboard_State, events) == 1544, "fb_Keyboard_State.events");
_Static_assert(offsetof(fb_Keyboard_State, held) == 1560, "fb_Keyboard_State.held");
_Static_assert(offsetof(fb_Keyboard_State, simulated) == 4664, "fb_Keyboard_State.simulated");

typedef struct fb_Mouse_State fb_Mouse_State;
struct fb_Mouse_State {
    _Bool inside;
    fb_Vector2 position;
    fb_Vector2 scroll_delta;
    fb_Cursor cursor;
    fb_Vector2 press_position[5];
    _Bool pressed[5];
    _Bool released[5];
    _Bool held[5];
};
_Static_assert(sizeof(fb_Mouse_State) == 80, "fb_Mouse_State");
_Static_assert(offsetof(fb_Mouse_State, inside) == 0, "fb_Mouse_State.inside");
_Static_assert(offsetof(fb_Mouse_State, position) == 4, "fb_Mouse_State.position");
_Static_assert(offsetof(fb_Mouse_State, scroll_delta) == 12, "fb_Mouse_State.scroll_delta");
_Static_assert(offsetof(fb_Mouse_State, cursor) == 20, "fb_Mouse_State.cursor");
_Static_assert(offsetof(fb_Mouse_State, press_position) == 24, "fb_Mouse_State.press_position");
_Static_assert(offsetof(fb_Mouse_State, pressed) == 64, "fb_Mouse_State.pressed");
_Static_assert(offsetof(fb_Mouse_State, released) == 69, "fb_Mouse_State.released");
_Static_assert(offsetof(fb_Mouse_State, held) == 74, "fb_Mouse_State.held");

struct fb_Windows_GL_Window {
    void * hwnd;
    void * hdc;
    fb_Windows_GL_Backend * backend;
    double width;
    double height;
    double min_width;
    double min_height;
    double max_width;
    double max_height;
    double scale;
    fb_Preferred_Theme theme;
    uint8_t text_buffer[256];
    fb_String text;
    fb_Keyboard_State keyboard_state;
    fb_Mouse_State mouse_state;
    _Bool running;
};
_Static_assert(sizeof(fb_Windows_GL_Window) == 5120, "fb_Windows_GL_Window");
_Static_assert(offsetof(fb_Windows_GL_Window, hwnd) == 0, "fb_Windows_GL_Window.hwnd");
_Static_assert(offsetof(fb_Windows_GL_Window, hdc) == 8, "fb_Windows_GL_Window.hdc");
_Static_assert(offsetof(fb_Windows_GL_Window, backend) == 16, "fb_Windows_GL_Window.backend");
_Static_assert(offsetof(fb_Windows_GL_Window, width) == 24, "fb_Windows_GL_Window.width");
_Static_assert(offsetof(fb_Windows_GL_Window, height) == 32, "fb_Windows_GL_Window.height");
_Static_assert(offsetof(fb_Windows_GL_Window, min_width) == 40, "fb_Windows_GL_Window.min_width");
_Static_assert(offsetof(fb_Windows_GL_Window, min_height) == 48, "fb_Windows_GL_Window.min_height");
_Static_assert(offsetof(fb_Windows_GL_Window, max_width) == 56, "fb_Windows_GL_Window.max_width");
_Static_assert(offsetof(fb_Windows_GL_Window, max_height) == 64, "fb_Windows_GL_Window.max_height");
_Static_assert(offsetof(fb_Windows_GL_Window, scale) == 72, "fb_Windows_GL_Window.scale");
_Static_assert(offsetof(fb_Windows_GL_Window, theme) == 80, "fb_Windows_GL_Window.theme");
_Static_assert(offsetof(fb_Windows_GL_Window, text_buffer) == 84, "fb_Windows_GL_Window.text_buffer");
_Static_assert(offsetof(fb_Windows_GL_Window, text) == 344, "fb_Windows_GL_Window.text");
_Static_assert(offsetof(fb_Windows_GL_Window, keyboard_state) == 360, "fb_Windows_GL_Window.keyboard_state");
_Static_assert(offsetof(fb_Windows_GL_Window, mouse_state) == 5032, "fb_Windows_GL_Window.mouse_state");
_Static_assert(offsetof(fb_Windows_GL_Window, running) == 5112, "fb_Windows_GL_Window.running");

struct fb_Forbear {
    fb_Array_Node node_tree;
    fb_Array_Node_Measurement measurements;
    int64_t frame;
    float delta_time;
    double last_frame_time;
    fb_Allocator persistent_allocator;
    int64_t parent_index;
    void * state_buffers;
    fb_Pool_Slot pool_slots[256];
    uint64_t scope_key;
    fb_Base_Style base_style;
    uint16_t font_counter;
    int64_t state_current;
    int64_t state_used;
    void * freetype_library;
    void * shaping_context;
    uint32_t shader_program;
    uint32_t shader_vao;
    uint32_t node_vbo;
    fb_Glyph_Atlas glyph_atlas;
    fb_Windows_GL_Window * window;
    fb_Windows_GL_Backend * backend;
};
_Static_assert(sizeof(fb_Forbear) == 18792, "fb_Forbear");
_Static_assert(offsetof(fb_Forbear, node_tree) == 0, "fb_Forbear.node_tree");
_Static_assert(offsetof(fb_Forbear, measurements) == 40, "fb_Forbear.measurements");
_Static_assert(offsetof(fb_Forbear, frame) == 80, "fb_Forbear.frame");
_Static_assert(offsetof(fb_Forbear, delta_time) == 88, "fb_Forbear.delta_time");
_Static_assert(offsetof(fb_Forbear, last_frame_time) == 96, "fb_Forbear.last_frame_time");
_Static_assert(offsetof(fb_Forbear, persistent_allocator) == 104, "fb_Forbear.persistent_allocator");
_Static_assert(offsetof(fb_Forbear, parent_index) == 120, "fb_Forbear.parent_index");
_Static_assert(offsetof(fb_Forbear, state_buffers) == 128, "fb_Forbear.state_buffers");
_Static_assert(offsetof(fb_Forbear, pool_slots) == 136, "fb_Forbear.pool_slots");
_Static_assert(offsetof(fb_Forbear, scope_key) == 18568, "fb_Forbear.scope_key");
_Static_assert(offsetof(fb_Forbear, base_style) == 18576, "fb_Forbear.base_style");
_Static_assert(offsetof(fb_Forbear, font_counter) == 18632, "fb_Forbear.font_counter");
_Static_assert(offsetof(fb_Forbear, state_current) == 18640, "fb_Forbear.state_current");
_Static_assert(offsetof(fb_Forbear, state_used) == 18648, "fb_Forbear.state_used");
_Static_assert(offsetof(fb_Forbear, freetype_library) == 18656, "fb_Forbear.freetype_library");
_Static_assert(offsetof(fb_Forbear, shaping_context) == 18664, "fb_Forbear.shaping_context");
_Static_assert(offsetof(fb_Forbear, shader_program) == 18672, "fb_Forbear.shader_program");
_Static_assert(offsetof(fb_Forbear, shader_vao) == 18676, "fb_Forbear.shader_vao");
_Static_assert(offsetof(fb_Forbear, node_vbo) == 18680, "fb_Forbear.node_vbo");
_Static_assert(offsetof(fb_Forbear, glyph_atlas) == 18688, "fb_Forbear.glyph_atlas");
_Static_assert(offsetof(fb_Forbear, window) == 18776, "fb_Forbear.window");
_Static_assert(offsetof(fb_Forbear, backend) == 18784, "fb_Forbear.backend");

typedef int64_t fb_Mouse_Button;
#define FB_MOUSE_BUTTON_LEFT 0
#define FB_MOUSE_BUTTON_RIGHT 1
#define FB_MOUSE_BUTTON_MIDDLE 2
#define FB_MOUSE_BUTTON_BACK 3
#define FB_MOUSE_BUTTON_FORWARD 4

typedef fb_Windows_GL_Window fb_Window;
typedef fb_Windows_GL_Backend fb_Backend;

fb_String fb_get_text_input(void);
void fb_copy_to_clipboard(const char * text);
fb_String fb_get_clipboard_text(void);
_Bool fb_is_mouse_inside(void);
double fb_get_last_frame_time(void);
float fb_get_delta_time(void);
typedef float (*fb_Proc_float_float)(float);
float fb_use_transition_f(float value, float duration, fb_Proc_float_float easing);
void fb_text(const char * content, const char * key);
void * fb_node_realloc(void * memory, int64_t size, int64_t old_size);
void * fb_node_alloc(int64_t size);
void * fb_frame_realloc(void * memory, int64_t size, int64_t old_size);
void * fb_frame_alloc(int64_t size);
void * fb_state(int64_t size, void * initial);
void fb_prepare_for_next_frame(void);
void fb_layout(void);
_Bool fb_on_key_up(fb_Key key);
_Bool fb_on_key_down(fb_Key key, _Bool on_repeat);
_Bool fb_on_click(fb_Mouse_Button button, _Bool check_inside, _Bool movement_threshold);
_Bool fb_on_mouse_up(fb_Mouse_Button button, _Bool check_inside);
_Bool fb_on_mouse_down(fb_Mouse_Button button, _Bool check_inside);
_Bool fb_is_mouse_held(fb_Mouse_Button button);
_Bool fb_is_dragging(fb_Mouse_Button button);
fb_Vector2 fb_get_press_position(fb_Mouse_Button button);
fb_Vector2 fb_get_scroll_delta(void);
fb_Vector2 fb_get_mouse_position(void);
void fb_set_cursor(fb_Cursor cursor);
fb_Preferred_Theme fb_get_preferred_theme(void);
fb_Vector2 fb_get_viewport_size(void);
fb_Node * fb_get_node(int64_t node_index);
_Bool fb_get_measurement(int64_t node_index, _Bool include_scopes, fb_Node_Measurement * out);
void fb_complete_with(fb_Style style, fb_Base_Style base, fb_Complete_Style * out);
fb_Style fb_overwrite(fb_Style overwritten, fb_Style overwriter);
fb_Placement fb_relative(fb_Vector2 value, fb_Corner corner);
fb_Placement fb_fixed_placement(fb_Vector2 value, fb_Corner corner);
fb_Placement fb_flow(void);
fb_Vector4 fb_rgba(float r, float g, float b, float a);
fb_Vector4 fb_rgb(float r, float g, float b);
fb_Background fb_gradient(fb_Linear_Gradient value);
fb_Background fb_color(fb_Vector4 value);
fb_Vector2 fb_to_bottom_right(void);
fb_Vector2 fb_to_bottom_left(void);
fb_Vector2 fb_to_top_right(void);
fb_Vector2 fb_to_top_left(void);
fb_Vector2 fb_to_right(void);
fb_Vector2 fb_to_left(void);
fb_Vector2 fb_to_bottom(void);
fb_Vector2 fb_to_top(void);
fb_Vector2 fb_angle(float degrees);
fb_Base_Style fb_from(fb_Complete_Style style);
void fb_use_scrolling(fb_Scrolling_State * state);
void fb_schedule_scroll(fb_Scrolling_State * state, fb_Vector2 position, _Bool animate);
fb_Vector4 fb_use_transition_v4(fb_Vector4 value, float duration, fb_Proc_float_float easing);
fb_Vector3 fb_use_transition_v3(fb_Vector3 value, float duration, fb_Proc_float_float easing);
fb_Vector2 fb_use_transition_v2(fb_Vector2 value, float duration, fb_Proc_float_float easing);
fb_Line_Height fb_line_height_fixed(float value);
fb_Line_Height fb_line_height_percentage(float value);
fb_Sides fb_with_bottom_sides(fb_Sides sides, float value);
fb_Sides fb_bottom_sides(float value);
fb_Sides fb_with_top_sides(fb_Sides sides, float value);
fb_Sides fb_top_sides(float value);
fb_Sides fb_with_right_sides(fb_Sides sides, float value);
fb_Sides fb_right_sides(float value);
fb_Sides fb_with_left_sides(fb_Sides sides, float value);
fb_Sides fb_left_sides(float value);
fb_Sides fb_with_block_sides(fb_Sides sides, float value);
fb_Sides fb_block_sides(float value);
fb_Sides fb_with_in_line_sides(fb_Sides sides, float value);
fb_Sides fb_in_line_sides(float value);
fb_Sides fb_all_sides(float value);
fb_Sizing fb_grow(float value);
fb_Sizing fb_fixed(float value);
fb_Sizing fb_fit(void);
fb_Direction fb_opposite(fb_Direction direction);
void fb_stext(fb_Style style, const char * content, const char * key);
void fb_close_scope(fb_Node_Opening_Data data);
fb_Node_Opening_Data fb_open_scope(const char * key);
void fb_close_element(fb_Node_Opening_Data data);
fb_Node_Opening_Data fb_open_element(fb_Style style, const char * key);
void fb_draw(fb_Vector4 clearing_color);
void fb_init_font(fb_Font * font);
fb_Font fb_create_font(fb_String memory);
void fb_update_backend(fb_Windows_GL_Backend * backend);
void fb_init_window(fb_Windows_GL_Backend * backend, fb_Windows_GL_Window * window, double width, double height, const char * title, double min_width, double min_height, double max_width, double max_height);
void fb_init_backend(fb_Windows_GL_Backend * backend);
void fb_init_forbear(fb_Forbear * forbear, fb_Windows_GL_Backend * program_backend, fb_Windows_GL_Window * program_window, fb_Base_Style program_base_style);
void __jai_runtime_fini(void * _context);
_Bool fb_is_key_held(fb_Key key);
void * __jai_runtime_init(int32_t argc, void * argv);
typedef struct fb_Spring_Config_Vector4 fb_Spring_Config_Vector4;
struct fb_Spring_Config_Vector4 {
    float stiffness;
    float damping;
    float mass;
    fb_Vector4 * current;
};
_Static_assert(sizeof(fb_Spring_Config_Vector4) == 24, "fb_Spring_Config_Vector4");
_Static_assert(offsetof(fb_Spring_Config_Vector4, stiffness) == 0, "fb_Spring_Config_Vector4.stiffness");
_Static_assert(offsetof(fb_Spring_Config_Vector4, damping) == 4, "fb_Spring_Config_Vector4.damping");
_Static_assert(offsetof(fb_Spring_Config_Vector4, mass) == 8, "fb_Spring_Config_Vector4.mass");
_Static_assert(offsetof(fb_Spring_Config_Vector4, current) == 16, "fb_Spring_Config_Vector4.current");

fb_Vector4 fb_use_spring_transition_v4(fb_Vector4 target, fb_Spring_Config_Vector4 config);
typedef struct fb_Spring_Config_Vector3 fb_Spring_Config_Vector3;
struct fb_Spring_Config_Vector3 {
    float stiffness;
    float damping;
    float mass;
    fb_Vector3 * current;
};
_Static_assert(sizeof(fb_Spring_Config_Vector3) == 24, "fb_Spring_Config_Vector3");
_Static_assert(offsetof(fb_Spring_Config_Vector3, stiffness) == 0, "fb_Spring_Config_Vector3.stiffness");
_Static_assert(offsetof(fb_Spring_Config_Vector3, damping) == 4, "fb_Spring_Config_Vector3.damping");
_Static_assert(offsetof(fb_Spring_Config_Vector3, mass) == 8, "fb_Spring_Config_Vector3.mass");
_Static_assert(offsetof(fb_Spring_Config_Vector3, current) == 16, "fb_Spring_Config_Vector3.current");

fb_Vector3 fb_use_spring_transition_v3(fb_Vector3 target, fb_Spring_Config_Vector3 config);
typedef struct fb_Spring_Config_Vector2 fb_Spring_Config_Vector2;
struct fb_Spring_Config_Vector2 {
    float stiffness;
    float damping;
    float mass;
    fb_Vector2 * current;
};
_Static_assert(sizeof(fb_Spring_Config_Vector2) == 24, "fb_Spring_Config_Vector2");
_Static_assert(offsetof(fb_Spring_Config_Vector2, stiffness) == 0, "fb_Spring_Config_Vector2.stiffness");
_Static_assert(offsetof(fb_Spring_Config_Vector2, damping) == 4, "fb_Spring_Config_Vector2.damping");
_Static_assert(offsetof(fb_Spring_Config_Vector2, mass) == 8, "fb_Spring_Config_Vector2.mass");
_Static_assert(offsetof(fb_Spring_Config_Vector2, current) == 16, "fb_Spring_Config_Vector2.current");

fb_Vector2 fb_use_spring_transition_v2(fb_Vector2 target, fb_Spring_Config_Vector2 config);
typedef struct fb_Spring_Config_float fb_Spring_Config_float;
struct fb_Spring_Config_float {
    float stiffness;
    float damping;
    float mass;
    float * current;
};
_Static_assert(sizeof(fb_Spring_Config_float) == 24, "fb_Spring_Config_float");
_Static_assert(offsetof(fb_Spring_Config_float, stiffness) == 0, "fb_Spring_Config_float.stiffness");
_Static_assert(offsetof(fb_Spring_Config_float, damping) == 4, "fb_Spring_Config_float.damping");
_Static_assert(offsetof(fb_Spring_Config_float, mass) == 8, "fb_Spring_Config_float.mass");
_Static_assert(offsetof(fb_Spring_Config_float, current) == 16, "fb_Spring_Config_float.current");

float fb_use_spring_transition_f(float target, fb_Spring_Config_float config);
#endif

#if defined(__linux__)
typedef struct { int64_t count; uint8_t *data; } fb_String;
typedef struct fb_Vector3 fb_Vector3;
struct fb_Vector3 {
    float x;
    float y;
    float z;
};
_Static_assert(sizeof(fb_Vector3) == 12, "fb_Vector3");
_Static_assert(offsetof(fb_Vector3, x) == 0, "fb_Vector3.x");
_Static_assert(offsetof(fb_Vector3, y) == 4, "fb_Vector3.y");
_Static_assert(offsetof(fb_Vector3, z) == 8, "fb_Vector3.z");

typedef struct fb_Scrolling_State fb_Scrolling_State;
typedef struct fb_Vector2 fb_Vector2;
struct fb_Vector2 {
    float x;
    float y;
};
_Static_assert(sizeof(fb_Vector2) == 8, "fb_Vector2");
_Static_assert(offsetof(fb_Vector2, x) == 0, "fb_Vector2.x");
_Static_assert(offsetof(fb_Vector2, y) == 4, "fb_Vector2.y");

typedef struct fb_Scheduled_Scroll fb_Scheduled_Scroll;
struct fb_Scheduled_Scroll {
    _Bool defined;
    _Bool defined_this_frame;
    fb_Vector2 position;
    _Bool animate;
};
_Static_assert(sizeof(fb_Scheduled_Scroll) == 16, "fb_Scheduled_Scroll");
_Static_assert(offsetof(fb_Scheduled_Scroll, defined) == 0, "fb_Scheduled_Scroll.defined");
_Static_assert(offsetof(fb_Scheduled_Scroll, defined_this_frame) == 1, "fb_Scheduled_Scroll.defined_this_frame");
_Static_assert(offsetof(fb_Scheduled_Scroll, position) == 4, "fb_Scheduled_Scroll.position");
_Static_assert(offsetof(fb_Scheduled_Scroll, animate) == 12, "fb_Scheduled_Scroll.animate");

struct fb_Scrolling_State {
    fb_Vector2 offset;
    fb_Vector2 effective_offset;
    fb_Scheduled_Scroll scheduled_scroll;
};
_Static_assert(sizeof(fb_Scrolling_State) == 32, "fb_Scrolling_State");
_Static_assert(offsetof(fb_Scrolling_State, offset) == 0, "fb_Scrolling_State.offset");
_Static_assert(offsetof(fb_Scrolling_State, effective_offset) == 8, "fb_Scrolling_State.effective_offset");
_Static_assert(offsetof(fb_Scrolling_State, scheduled_scroll) == 16, "fb_Scrolling_State.scheduled_scroll");

typedef struct fb_Complete_Style fb_Complete_Style;
typedef struct fb_Background fb_Background;
typedef uint8_t fb_Background_Kind;
#define FB_BACKGROUND_KIND_COLOR 0
#define FB_BACKGROUND_KIND_GRADIENT 1

typedef struct fb_Vector4 fb_Vector4;
struct fb_Vector4 {
    float x;
    float y;
    float z;
    float w;
};
_Static_assert(sizeof(fb_Vector4) == 16, "fb_Vector4");
_Static_assert(offsetof(fb_Vector4, x) == 0, "fb_Vector4.x");
_Static_assert(offsetof(fb_Vector4, y) == 4, "fb_Vector4.y");
_Static_assert(offsetof(fb_Vector4, z) == 8, "fb_Vector4.z");
_Static_assert(offsetof(fb_Vector4, w) == 12, "fb_Vector4.w");

typedef struct fb_Linear_Gradient fb_Linear_Gradient;
typedef struct fb_Gradient_Stop fb_Gradient_Stop;
struct fb_Gradient_Stop {
    fb_Vector4 color;
    float position;
};
_Static_assert(sizeof(fb_Gradient_Stop) == 20, "fb_Gradient_Stop");
_Static_assert(offsetof(fb_Gradient_Stop, color) == 0, "fb_Gradient_Stop.color");
_Static_assert(offsetof(fb_Gradient_Stop, position) == 16, "fb_Gradient_Stop.position");

typedef struct { int64_t count; fb_Gradient_Stop *data; } fb_View_Gradient_Stop;

struct fb_Linear_Gradient {
    fb_View_Gradient_Stop stops;
    fb_Vector2 direction;
};
_Static_assert(sizeof(fb_Linear_Gradient) == 24, "fb_Linear_Gradient");
_Static_assert(offsetof(fb_Linear_Gradient, stops) == 0, "fb_Linear_Gradient.stops");
_Static_assert(offsetof(fb_Linear_Gradient, direction) == 16, "fb_Linear_Gradient.direction");

struct fb_Background {
    fb_Background_Kind kind;
    union {
    fb_Vector4 color;
    fb_Linear_Gradient gradient;
    };
};
_Static_assert(sizeof(fb_Background) == 32, "fb_Background");
_Static_assert(offsetof(fb_Background, kind) == 0, "fb_Background.kind");

typedef struct fb_Sides fb_Sides;
struct fb_Sides {
    fb_Vector2 x;
    fb_Vector2 y;
};
_Static_assert(sizeof(fb_Sides) == 16, "fb_Sides");
_Static_assert(offsetof(fb_Sides, x) == 0, "fb_Sides.x");
_Static_assert(offsetof(fb_Sides, y) == 8, "fb_Sides.y");

typedef uint32_t fb_Border_Style;
#define FB_BORDER_STYLE_SOLID 0
#define FB_BORDER_STYLE_DASHED 1

typedef struct fb_Shadow fb_Shadow;
struct fb_Shadow {
    fb_Sides offset;
    float blur_radius;
    float spread;
    fb_Vector4 color;
};
_Static_assert(sizeof(fb_Shadow) == 40, "fb_Shadow");
_Static_assert(offsetof(fb_Shadow, offset) == 0, "fb_Shadow.offset");
_Static_assert(offsetof(fb_Shadow, blur_radius) == 16, "fb_Shadow.blur_radius");
_Static_assert(offsetof(fb_Shadow, spread) == 20, "fb_Shadow.spread");
_Static_assert(offsetof(fb_Shadow, color) == 24, "fb_Shadow.color");

typedef struct fb_Font fb_Font;
struct fb_Font {
    fb_String memory;
    void * raster_face;
    _Alignas(8) uint8_t shaping_font[72];
    uint16_t key;
    uint16_t weight;
};
_Static_assert(sizeof(fb_Font) == 104, "fb_Font");
_Static_assert(offsetof(fb_Font, memory) == 0, "fb_Font.memory");
_Static_assert(offsetof(fb_Font, raster_face) == 16, "fb_Font.raster_face");
_Static_assert(offsetof(fb_Font, shaping_font) == 24, "fb_Font.shaping_font");
_Static_assert(offsetof(fb_Font, key) == 96, "fb_Font.key");
_Static_assert(offsetof(fb_Font, weight) == 98, "fb_Font.weight");

typedef uint32_t fb_Language;
#define FB_LANGUAGE_DONT_KNOW 0
#define FB_LANGUAGE_A_HMAO 541347144
#define FB_LANGUAGE_AARI 541676097
#define FB_LANGUAGE_ABAZA 541147713
#define FB_LANGUAGE_ABKHAZIAN 541803073
#define FB_LANGUAGE_ACHI 542262081
#define FB_LANGUAGE_ACHOLI 541606721
#define FB_LANGUAGE_ADYGHE 542721089
#define FB_LANGUAGE_AFAR 542262849
#define FB_LANGUAGE_AFRIKAANS 541804097
#define FB_LANGUAGE_AGAW 542590785
#define FB_LANGUAGE_AITON 542067009
#define FB_LANGUAGE_AKAN 541150017
#define FB_LANGUAGE_ALBANIAN 541675859
#define FB_LANGUAGE_ALSATIAN 542329921
#define FB_LANGUAGE_ALTAI 542395457
#define FB_LANGUAGE_ALUO 541150809
#define FB_LANGUAGE_AMERICAN_PHONETIC 1213222977
#define FB_LANGUAGE_AMHARIC 541609281
#define FB_LANGUAGE_ANGLO_SAXON 541544001
#define FB_LANGUAGE_ARABIC 541151809
#define FB_LANGUAGE_ARAGONESE 541545025
#define FB_LANGUAGE_ARAKANESE 541807169
#define FB_LANGUAGE_ARAKWAL 542591826
#define FB_LANGUAGE_ARMENIAN 541415752
#define FB_LANGUAGE_ARMENIAN_EAST 809851208
#define FB_LANGUAGE_AROMANIAN 542135634
#define FB_LANGUAGE_ARPITAN 542134854
#define FB_LANGUAGE_ASSAMESE 541938497
#define FB_LANGUAGE_ASTURIAN 542397249
#define FB_LANGUAGE_ATHAPASKAN 541611073
#define FB_LANGUAGE_ATSINA 542331969
#define FB_LANGUAGE_AVAR 542266945
#define FB_LANGUAGE_AVATIME 542004801
#define FB_LANGUAGE_AWADHI 541153089
#define FB_LANGUAGE_AYMARA 541940033
#define FB_LANGUAGE_AZERBAIJANI 541416001
#define FB_LANGUAGE_BADAGA 541344066
#define FB_LANGUAGE_BAGHELKHANDI 541540674
#define FB_LANGUAGE_BAGRI 542197570
#define FB_LANGUAGE_BALANTE 542002242
#define FB_LANGUAGE_BALINESE 541999426
#define FB_LANGUAGE_BALKAR 541868354
#define FB_LANGUAGE_BALTI 542395458
#define FB_LANGUAGE_BALUCHI 541674562
#define FB_LANGUAGE_BAMBARA 541216066
#define FB_LANGUAGE_BAMILEKE 541871426
#define FB_LANGUAGE_BANDA 809779522
#define FB_LANGUAGE_BANDJALANG 542721090
#define FB_LANGUAGE_BANGLA 542000450
#define FB_LANGUAGE_BASHKIR 541610818
#define FB_LANGUAGE_BASQUE 542201157
#define FB_LANGUAGE_BATAK 541807682
#define FB_LANGUAGE_BATAK_ALAS_KLUET 542790722
#define FB_LANGUAGE_BATAK_ANGKOLA 541215553
#define FB_LANGUAGE_BATAK_DAIRI 541348930
#define FB_LANGUAGE_BATAK_KARO 542659650
#define FB_LANGUAGE_BATAK_MANDAILING 541938754
#define FB_LANGUAGE_BATAK_SIMALUNGUN 542331970
#define FB_LANGUAGE_BATAK_TOBA 541278786
#define FB_LANGUAGE_BAULE 542458178
#define FB_LANGUAGE_BAVARIAN 542261570
#define FB_LANGUAGE_BELARUSIAN 541869378
#define FB_LANGUAGE_BEMBA 541934914
#define FB_LANGUAGE_BENCH 541606722
#define FB_LANGUAGE_BERBER 542261826
#define FB_LANGUAGE_BETI 541676610
#define FB_LANGUAGE_BETTE_KURUMA 541218136
#define FB_LANGUAGE_BHILI 541673538
#define FB_LANGUAGE_BHOJPURI 542066754
#define FB_LANGUAGE_BHUTANESE 542005828
#define FB_LANGUAGE_BIBLE_CREE 542262082
#define FB_LANGUAGE_BIKOL 541804866
#define FB_LANGUAGE_BILEN 541870402
#define FB_LANGUAGE_BISHNUPRIYA_MANIPURI 542724162
#define FB_LANGUAGE_BISLAMA 542329154
#define FB_LANGUAGE_BLACKFOOT 541477698
#define FB_LANGUAGE_BODO 542659138
#define FB_LANGUAGE_BOSNIAN 542330690
#define FB_LANGUAGE_BOUYEI 541279056
#define FB_LANGUAGE_BRAHUI 541610562
#define FB_LANGUAGE_BRAJ_BHASHA 541676098
#define FB_LANGUAGE_BRETON 541413954
#define FB_LANGUAGE_BUGIS 541545794
#define FB_LANGUAGE_BULGARIAN 542263106
#define FB_LANGUAGE_BUMTHANGKHA 542788171
#define FB_LANGUAGE_BURMESE 541938242
#define FB_LANGUAGE_BURUSHASKI 541807426
#define FB_LANGUAGE_CAJUN_FRENCH 541282886
#define FB_LANGUAGE_CARRIER 542265923
#define FB_LANGUAGE_CATALAN 542392643
#define FB_LANGUAGE_CAYUGA 542720323
#define FB_LANGUAGE_CEBUANO 541214019
#define FB_LANGUAGE_CENTRAL_YUPIK 542462789
#define FB_LANGUAGE_CHAHA_GURAGE 541542467
#define FB_LANGUAGE_CHAMORRO 541149251
#define FB_LANGUAGE_CHATTISGARHI 541608003
#define FB_LANGUAGE_CHECHEN 541411395
#define FB_LANGUAGE_CHEROKEE 542263363
#define FB_LANGUAGE_CHEYENNE 542722115
#define FB_LANGUAGE_CHICHEWA 541673539
#define FB_LANGUAGE_CHIGA 541542211
#define FB_LANGUAGE_CHIMILA 541540931
#define FB_LANGUAGE_CHIN 542001489
#define FB_LANGUAGE_CHINANTEC 1313358659
#define FB_LANGUAGE_CHINESE_PHONETIC 542132314
#define FB_LANGUAGE_CHINESE_SIMPLIFIED 542328922
#define FB_LANGUAGE_CHINESE_TRADITIONAL 542394458
#define FB_LANGUAGE_CHINESE_TRADITIONAL_HONG_KONG 541608026
#define FB_LANGUAGE_CHINESE_TRADITIONAL_MACAO 1297369178
#define FB_LANGUAGE_CHIPEWYAN 542132291
#define FB_LANGUAGE_CHITTAGONIAN 541545539
#define FB_LANGUAGE_CHOCTAW 542066755
#define FB_LANGUAGE_CHUKCHI 541804611
#define FB_LANGUAGE_CHURCH_SLAVONIC 541872963
#define FB_LANGUAGE_CHUUKESE 810240067
#define FB_LANGUAGE_CHUVASH 542459971
#define FB_LANGUAGE_COMORIAN 542264643
#define FB_LANGUAGE_COMOX 542068547
#define FB_LANGUAGE_COPTIC 542134083
#define FB_LANGUAGE_CORNISH 542265155
#define FB_LANGUAGE_CORSICAN 542330691
#define FB_LANGUAGE_CREE 541413955
#define FB_LANGUAGE_CREOLES 542134339
#define FB_LANGUAGE_CRIMEAN_TATAR 542396995
#define FB_LANGUAGE_CRIOULO 541148491
#define FB_LANGUAGE_CROATIAN 542528072
#define FB_LANGUAGE_CYPRIOT_ARABIC 542720833
#define FB_LANGUAGE_CZECH 542724931
#define FB_LANGUAGE_DAGBANI 541540676
#define FB_LANGUAGE_DAN 541740612
#define FB_LANGUAGE_DANGME 541544004
#define FB_LANGUAGE_DANISH 541999428
#define FB_LANGUAGE_DARGWA 542261572
#define FB_LANGUAGE_DARI 541676100
#define FB_LANGUAGE_DAYI 542654788
#define FB_LANGUAGE_DEFAULT 1953261156
#define FB_LANGUAGE_DEHONG_DAI 541344852
#define FB_LANGUAGE_DHANGU 541542468
#define FB_LANGUAGE_DHIVEHI 542525764
#define FB_LANGUAGE_DHUWAL 541742404
#define FB_LANGUAGE_DIMLI 542198084
#define FB_LANGUAGE_DINKA 541806148
#define FB_LANGUAGE_DIVEHI 542525764
#define FB_LANGUAGE_DJAMBARRPUYNGU 810699332
#define FB_LANGUAGE_DOGRI 542066500
#define FB_LANGUAGE_DOGRI_MACROLANGUAGE 542263108
#define FB_LANGUAGE_DUNGAN 542004548
#define FB_LANGUAGE_DUTCH 541346894
#define FB_LANGUAGE_DZONGKHA 542005828
#define FB_LANGUAGE_EASTERN_ABENAKI 542196033
#define FB_LANGUAGE_EASTERN_CHAM 541936195
#define FB_LANGUAGE_EASTERN_CREE 542262085
#define FB_LANGUAGE_EASTERN_MANINKAKAN 541805893
#define FB_LANGUAGE_EASTERN_PWO_KAREN 542132811
#define FB_LANGUAGE_EBIRA 541672005
#define FB_LANGUAGE_EDO 542065733
#define FB_LANGUAGE_EFIK 541673029
#define FB_LANGUAGE_EMBERA_BAUDO 541279298
#define FB_LANGUAGE_EMBERA_CATIO 542069827
#define FB_LANGUAGE_EMBERA_CHAMI 541674819
#define FB_LANGUAGE_EMBERA_TADO 541279316
#define FB_LANGUAGE_ENGLISH 541544005
#define FB_LANGUAGE_EPENA 541149779
#define FB_LANGUAGE_ERZYA 542790213
#define FB_LANGUAGE_ESPERANTO 542069838
#define FB_LANGUAGE_ESTONIAN 541676613
#define FB_LANGUAGE_EVEN 542004805
#define FB_LANGUAGE_EVENKI 541808197
#define FB_LANGUAGE_EWE 541415237
#define FB_LANGUAGE_FALAM_CHIN 541868360
#define FB_LANGUAGE_FANG 810434886
#define FB_LANGUAGE_FANTI 542392646
#define FB_LANGUAGE_FAROESE 542330694
#define FB_LANGUAGE_FEFE 542133574
#define FB_LANGUAGE_FIJIAN 541674054
#define FB_LANGUAGE_FILIPINO 541870416
#define FB_LANGUAGE_FINNISH 542001478
#define FB_LANGUAGE_FLEMISH 541412422
#define FB_LANGUAGE_FON 542003014
#define FB_LANGUAGE_FOREST_ENETS 541412934
#define FB_LANGUAGE_FRENCH 541151814
#define FB_LANGUAGE_FRENCH_ANTILLEAN 541999430
#define FB_LANGUAGE_FRISIAN 541676102
#define FB_LANGUAGE_FRIULIAN 541872710
#define FB_LANGUAGE_FULAH 541873478
#define FB_LANGUAGE_FUTA 541152326
#define FB_LANGUAGE_GA 541344071
#define FB_LANGUAGE_GAGAUZ 541540679
#define FB_LANGUAGE_GALICIAN 541868359
#define FB_LANGUAGE_GANDA 541545804
#define FB_LANGUAGE_GARHWALI 542589255
#define FB_LANGUAGE_GARO 542069319
#define FB_LANGUAGE_GARSHUNI 542261575
#define FB_LANGUAGE_GEBA_KAREN 542201419
#define FB_LANGUAGE_GEEZ 542786887
#define FB_LANGUAGE_GEORGIAN 542392651
#define FB_LANGUAGE_GEPO 542132057
#define FB_LANGUAGE_GERMAN 542459204
#define FB_LANGUAGE_GIKUYU 541804875
#define FB_LANGUAGE_GILAKI 541805639
#define FB_LANGUAGE_GILBERTESE 810305863
#define FB_LANGUAGE_GILYAK 541870407
#define FB_LANGUAGE_GITHABUL 541608263
#define FB_LANGUAGE_GOGO 541544263
#define FB_LANGUAGE_GONDI 542003015
#define FB_LANGUAGE_GREEK 541871173
#define FB_LANGUAGE_GREENLANDIC 542003783
#define FB_LANGUAGE_GUARANI 541152583
#define FB_LANGUAGE_GUINEA 542133063
#define FB_LANGUAGE_GUJARATI 541742407
#define FB_LANGUAGE_GUMATJ 542002759
#define FB_LANGUAGE_GUMUZ 542788935
#define FB_LANGUAGE_GUPAPUYNGU 541480263
#define FB_LANGUAGE_GUSII 542790983
#define FB_LANGUAGE_HAIDA 810107208
#define FB_LANGUAGE_HAITIAN_CREOLE 541671752
#define FB_LANGUAGE_HALKOMELEM 542266696
#define FB_LANGUAGE_HAMMER_BANNA 541999688
#define FB_LANGUAGE_HARARI 541676104
#define FB_LANGUAGE_HARAUTI 542261576
#define FB_LANGUAGE_HARYANVI 541280066
#define FB_LANGUAGE_HAUSA 542458184
#define FB_LANGUAGE_HAVASUPAI_WALAPAI_YAVAPAI 541480281
#define FB_LANGUAGE_HAWAIIAN 542589256
#define FB_LANGUAGE_HAYA 542720328
#define FB_LANGUAGE_HAZARAGI 542785864
#define FB_LANGUAGE_HEBREW 542267209
#define FB_LANGUAGE_HEILTSUK 541672776
#define FB_LANGUAGE_HERERO 542262600
#define FB_LANGUAGE_HIGH_MARI 541150536
#define FB_LANGUAGE_HILIGAYNON 541870408
#define FB_LANGUAGE_HINDI 542001480
#define FB_LANGUAGE_HINDKO 541347400
#define FB_LANGUAGE_HIRI_MOTU 542068040
#define FB_LANGUAGE_HMONG 542002504
#define FB_LANGUAGE_HMONG_DAW 542594893
#define FB_LANGUAGE_HMONG_SHUAT 542788936
#define FB_LANGUAGE_HO 538988360
#define FB_LANGUAGE_HUNGARIAN 542004552
#define FB_LANGUAGE_IBAN 541147721
#define FB_LANGUAGE_IBIBIO 541213257
#define FB_LANGUAGE_ICELANDIC 541872969
#define FB_LANGUAGE_IDO 542065737
#define FB_LANGUAGE_IGBO 542065225
#define FB_LANGUAGE_IJO 542067273
#define FB_LANGUAGE_ILOKANO 542067785
#define FB_LANGUAGE_INARI_SAMI 541938505
#define FB_LANGUAGE_INDONESIAN 541347401
#define FB_LANGUAGE_INGUSH 541544009
#define FB_LANGUAGE_INTERLINGUA 541150793
#define FB_LANGUAGE_INTERLINGUE 541412425
#define FB_LANGUAGE_INUKTITUT 542461513
#define FB_LANGUAGE_INUPIAT 541806665
#define FB_LANGUAGE_IPA_PHONETIC 542134345
#define FB_LANGUAGE_IRISH 541676105
#define FB_LANGUAGE_IRISH_TRADITIONAL 542397001
#define FB_LANGUAGE_IRULA 542462537
#define FB_LANGUAGE_ITALIAN 541152329
#define FB_LANGUAGE_JAMAICAN_CREOLE 541933898
#define FB_LANGUAGE_JAPANESE 541999434
#define FB_LANGUAGE_JAVANESE 542523722
#define FB_LANGUAGE_JENNU_KURUMA 541742424
#define FB_LANGUAGE_JUDEO_TAT 542393418
#define FB_LANGUAGE_JULA 541873482
#define FB_LANGUAGE_KABARDIAN 541213003
#define FB_LANGUAGE_KABYLE 809648459
#define FB_LANGUAGE_KACHCHI 541278539
#define FB_LANGUAGE_KADIWEU 541278795
#define FB_LANGUAGE_KALENJIN 541868363
#define FB_LANGUAGE_KALMYK 541936715
#define FB_LANGUAGE_KAMBA 541216075
#define FB_LANGUAGE_KANAUJI 541739586
#define FB_LANGUAGE_KANNADA 541999435
#define FB_LANGUAGE_KANURI 542264907
#define FB_LANGUAGE_KAQCHIKEL 541802819
#define FB_LANGUAGE_KARACHAY 542261579
#define FB_LANGUAGE_KARAIM 541938251
#define FB_LANGUAGE_KARAKALPAK 541807179
#define FB_LANGUAGE_KARELIAN 541872715
#define FB_LANGUAGE_KAREN 542003787
#define FB_LANGUAGE_KASHMIRI 541610827
#define FB_LANGUAGE_KASHUBIAN 541217603
#define FB_LANGUAGE_KATE 541543755
#define FB_LANGUAGE_KAZAKH 542785867
#define FB_LANGUAGE_KEBENA 541214027
#define FB_LANGUAGE_KEKCHI 541803851
#define FB_LANGUAGE_KHAKASS 541149259
#define FB_LANGUAGE_KHAMTI_SHAN 542394443
#define FB_LANGUAGE_KHAMYANG 542462795
#define FB_LANGUAGE_KHANTY_KAZIM 541804619
#define FB_LANGUAGE_KHANTY_SHURISHKAR 542328907
#define FB_LANGUAGE_KHANTY_VAKHI 542525515
#define FB_LANGUAGE_KHASI 541676363
#define FB_LANGUAGE_KHENGKHA 541477720
#define FB_LANGUAGE_KHINALUG 541739595
#define FB_LANGUAGE_KHMER 541935691
#define FB_LANGUAGE_KHORASANI_TURKIC 542788939
#define FB_LANGUAGE_KHOWAR 542591051
#define FB_LANGUAGE_KHUTSURI_GEORGIAN 541411147
#define FB_LANGUAGE_KICHE 541283665
#define FB_LANGUAGE_KIKONGO 542003019
#define FB_LANGUAGE_KILDIN_SAMI 541938507
#define FB_LANGUAGE_KINYARWANDA 541152594
#define FB_LANGUAGE_KIRMANJKI 542460235
#define FB_LANGUAGE_KISII 542329163
#define FB_LANGUAGE_KITUBA 542591821
#define FB_LANGUAGE_KODAGU 541347659
#define FB_LANGUAGE_KOKNI 542001995
#define FB_LANGUAGE_KOMI 541937483
#define FB_LANGUAGE_KOMI_PERMYAK 542134091
#define FB_LANGUAGE_KOMI_ZYRIAN 542789451
#define FB_LANGUAGE_KOMO 542068043
#define FB_LANGUAGE_KOMSO 542330187
#define FB_LANGUAGE_KONGO 810438475
#define FB_LANGUAGE_KONKANI 541806411
#define FB_LANGUAGE_KOORETE 542397003
#define FB_LANGUAGE_KOREAN 542265163
#define FB_LANGUAGE_KOREAN_OLD_HANGUL 541609803
#define FB_LANGUAGE_KORYAK 541808971
#define FB_LANGUAGE_KOSRAEAN 542330699
#define FB_LANGUAGE_KPELLE 541872203
#define FB_LANGUAGE_KPELLE_LIBERIA 541413464
#define FB_LANGUAGE_KRIO 541676107
#define FB_LANGUAGE_KRYMCHAK 542393162
#define FB_LANGUAGE_KUANYAMA 541152587
#define FB_LANGUAGE_KUBE 541476683
#define FB_LANGUAGE_KUI 541676875
#define FB_LANGUAGE_KULVI 541807947
#define FB_LANGUAGE_KUMAONI 542002507
#define FB_LANGUAGE_KUMYK 541939019
#define FB_LANGUAGE_KURDISH 542266699
#define FB_LANGUAGE_KURUKH 542463307
#define FB_LANGUAGE_KUY 542725451
#define FB_LANGUAGE_KWAKWALA 541808459
#define FB_LANGUAGE_KYRGYZ 542263627
#define FB_LANGUAGE_L_CREE 542262092
#define FB_LANGUAGE_LADAKHI 541803596
#define FB_LANGUAGE_LADIN 541344076
#define FB_LANGUAGE_LADINO 541349194
#define FB_LANGUAGE_LAHULI 541606220
#define FB_LANGUAGE_LAK 541802828
#define FB_LANGUAGE_LAKI 541674316
#define FB_LANGUAGE_LAMBANI 541933900
#define FB_LANGUAGE_LAMPUNG 542132812
#define FB_LANGUAGE_LAO 542064972
#define FB_LANGUAGE_LATIN 542392652
#define FB_LANGUAGE_LATVIAN 541677132
#define FB_LANGUAGE_LAZ 542785868
#define FB_LANGUAGE_LELEMI 541476172
#define FB_LANGUAGE_LEZGI 542786892
#define FB_LANGUAGE_LIGURIAN 541739340
#define FB_LANGUAGE_LIMBU 541216076
#define FB_LANGUAGE_LIMBURGISH 541935948
#define FB_LANGUAGE_LINGALA 542001484
#define FB_LANGUAGE_LIPO 542068812
#define FB_LANGUAGE_LISU 542329164
#define FB_LANGUAGE_LITHUANIAN 541611084
#define FB_LANGUAGE_LIV 542525772
#define FB_LANGUAGE_LOJBAN 542065226
#define FB_LANGUAGE_LOMA 541937484
#define FB_LANGUAGE_LOMBARD 542068044
#define FB_LANGUAGE_LOMWE 542592332
#define FB_LANGUAGE_LOW_MARI 541150540
#define FB_LANGUAGE_LOW_SAXON 542327886
#define FB_LANGUAGE_LOWER_SORBIAN 541217612
#define FB_LANGUAGE_LU 541344344
#define FB_LANGUAGE_LUBA_KATANGA 541218124
#define FB_LANGUAGE_LUBA_LULUA 541152588
#define FB_LANGUAGE_LULE_SAMI 541938508
#define FB_LANGUAGE_LUO 542070092
#define FB_LANGUAGE_LURI 541282892
#define FB_LANGUAGE_LUSHOOTSEED 542397772
#define FB_LANGUAGE_LUXEMBOURGISH 542790732
#define FB_LANGUAGE_LUYIA 541611340
#define FB_LANGUAGE_MACEDONIAN 541346637
#define FB_LANGUAGE_MADURA 541344077
#define FB_LANGUAGE_MAGAHI 541540685
#define FB_LANGUAGE_MAITHILI 541611085
#define FB_LANGUAGE_MAJANG 541737293
#define FB_LANGUAGE_MAKASAR 542264141
#define FB_LANGUAGE_MAKHUWA 541802829
#define FB_LANGUAGE_MAKONDE 541410379
#define FB_LANGUAGE_MALAGASY 541543501
#define FB_LANGUAGE_MALAY 542723149
#define FB_LANGUAGE_MALAYALAM 541868365
#define FB_LANGUAGE_MALAYALAM_REFORMED 542264397
#define FB_LANGUAGE_MALE 541412429
#define FB_LANGUAGE_MALINKE 542002253
#define FB_LANGUAGE_MALTESE 542331981
#define FB_LANGUAGE_MAM 541933901
#define FB_LANGUAGE_MANCHU 541606733
#define FB_LANGUAGE_MANDAR 542262349
#define FB_LANGUAGE_MANDINKA 541347405
#define FB_LANGUAGE_MANINKA 541806157
#define FB_LANGUAGE_MANIPURI 541675085
#define FB_LANGUAGE_MANO 542524749
#define FB_LANGUAGE_MANSI 541999437
#define FB_LANGUAGE_MANX 542658125
#define FB_LANGUAGE_MAORI 541676109
#define FB_LANGUAGE_MAPUDUNGUN 542130509
#define FB_LANGUAGE_MARATHI 542261581
#define FB_LANGUAGE_MARSHALLESE 541606221
#define FB_LANGUAGE_MARWARI 542589261
#define FB_LANGUAGE_MAYAN 542005581
#define FB_LANGUAGE_MAZANDERANI 542005837
#define FB_LANGUAGE_MBEMBE_TIGON 541153870
#define FB_LANGUAGE_MBO 542065229
#define FB_LANGUAGE_MBUNDU 541999693
#define FB_LANGUAGE_MEDUMBA 542529858
#define FB_LANGUAGE_MEEN 542000461
#define FB_LANGUAGE_MENDE 541410381
#define FB_LANGUAGE_MERU 542262605
#define FB_LANGUAGE_MEWATI 541938775
#define FB_LANGUAGE_MINANGKABAU 542001485
#define FB_LANGUAGE_MINJANGBAL 541215320
#define FB_LANGUAGE_MIRANDESE 541873997
#define FB_LANGUAGE_MIZO 542787917
#define FB_LANGUAGE_MOHAWK 541609805
#define FB_LANGUAGE_MOKSHA 541806413
#define FB_LANGUAGE_MOLDAVIAN 541871949
#define FB_LANGUAGE_MON 542003021
#define FB_LANGUAGE_MONGOLIAN 541544013
#define FB_LANGUAGE_MOOSE_CREE 542262093
#define FB_LANGUAGE_MORISYEN 541410893
#define FB_LANGUAGE_MOROCCAN 542265165
#define FB_LANGUAGE_MOSSI 542330957
#define FB_LANGUAGE_MUNDARI 542004557
#define FB_LANGUAGE_MUSCOGEE 542332237
#define FB_LANGUAGE_N_CREE 542262094
#define FB_LANGUAGE_NAGA_ASSAMESE 541540686
#define FB_LANGUAGE_NAGARI 542263118
#define FB_LANGUAGE_NAHUATL 541606222
#define FB_LANGUAGE_NANAI 541999438
#define FB_LANGUAGE_NASKAPI 542327118
#define FB_LANGUAGE_NAURUAN 542458190
#define FB_LANGUAGE_NAVAJO 542523726
#define FB_LANGUAGE_NDAU 541279310
#define FB_LANGUAGE_NDEBELE 541213774
#define FB_LANGUAGE_NDONGA 541541454
#define FB_LANGUAGE_NEAPOLITAN 542130510
#define FB_LANGUAGE_NEPALI 542131534
#define FB_LANGUAGE_NEWARI 542590286
#define FB_LANGUAGE_NGBAKA 541149006
#define FB_LANGUAGE_NIGERIAN_FULFULDE 542528838
#define FB_LANGUAGE_NIMADI 541413198
#define FB_LANGUAGE_NISI 542329166
#define FB_LANGUAGE_NIUEAN 542460238
#define FB_LANGUAGE_NKO 542067534
#define FB_LANGUAGE_NOGAI 541544270
#define FB_LANGUAGE_NORFOLK 541608272
#define FB_LANGUAGE_NORTH_SLAVEY 542327635
#define FB_LANGUAGE_NORTHERN_EMBERA 542133573
#define FB_LANGUAGE_NORTHERN_SAMI 541938510
#define FB_LANGUAGE_NORTHERN_SOTHO 542069582
#define FB_LANGUAGE_NORTHERN_TAI 541152334
#define FB_LANGUAGE_NORWAY_HOUSE_CREE 541280334
#define FB_LANGUAGE_NORWEGIAN 542265166
#define FB_LANGUAGE_NORWEGIAN_NYNORSK 542005582
#define FB_LANGUAGE_NOVIAL 542527310
#define FB_LANGUAGE_NUMANGGANG 542134094
#define FB_LANGUAGE_NUNAVIK_INUKTITUT 542461513
#define FB_LANGUAGE_NUU_CHAH_NULTH 541807950
#define FB_LANGUAGE_NYAMWEZI 541940046
#define FB_LANGUAGE_NYANKOLE 541870926
#define FB_LANGUAGE_OCCITAN 541672271
#define FB_LANGUAGE_ODIA 541676111
#define FB_LANGUAGE_OJI_CREE 542262095
#define FB_LANGUAGE_OJIBWAY 541215311
#define FB_LANGUAGE_OLD_IRISH 541149011
#define FB_LANGUAGE_OLD_JAVANESE 542589259
#define FB_LANGUAGE_ONEIDA 541412943
#define FB_LANGUAGE_ONONDAGA 542068303
#define FB_LANGUAGE_OROMO 542069327
#define FB_LANGUAGE_OSSETIAN 542331727
#define FB_LANGUAGE_PA_O_KAREN 541805634
#define FB_LANGUAGE_PALAUAN 542458192
#define FB_LANGUAGE_PALAUNG 541543504
#define FB_LANGUAGE_PALESTINIAN_ARAMAIC 541147472
#define FB_LANGUAGE_PALI 541868368
#define FB_LANGUAGE_PALPA 542130512
#define FB_LANGUAGE_PAMPANGAN 541933904
#define FB_LANGUAGE_PANGASINAN 541540688
#define FB_LANGUAGE_PAPIAMENTU 810565968
#define FB_LANGUAGE_PASHTO 542327120
#define FB_LANGUAGE_PATTANI_MALAY 541148749
#define FB_LANGUAGE_PENNSYLVANIA_GERMAN 541279312
#define FB_LANGUAGE_PERSIAN 542261574
#define FB_LANGUAGE_PHAKE 541805136
#define FB_LANGUAGE_PICARD 541344592
#define FB_LANGUAGE_PIEMONTESE 542330192
#define FB_LANGUAGE_PILAGA 541543504
#define FB_LANGUAGE_PITE_SAMI 541411923
#define FB_LANGUAGE_POCOMCHI 541609808
#define FB_LANGUAGE_POHNPEIAN 542003024
#define FB_LANGUAGE_POLISH 541805648
#define FB_LANGUAGE_POLYTONIC_GREEK 542263120
#define FB_LANGUAGE_PORTUGUESE 541545552
#define FB_LANGUAGE_PROVENCAL 542069328
#define FB_LANGUAGE_PUNJABI 541999440
#define FB_LANGUAGE_QUECHUA 542790993
#define FB_LANGUAGE_QUECHUA_BOLIVIA 541611345
#define FB_LANGUAGE_QUECHUA_ECUADOR 541677137
#define FB_LANGUAGE_QUECHUA_PERU 541611857
#define FB_LANGUAGE_R_CREE 542262098
#define FB_LANGUAGE_RAJASTHANI 541737298
#define FB_LANGUAGE_RAKHINE 541807169
#define FB_LANGUAGE_RAROTONGAN 542261586
#define FB_LANGUAGE_REJANG 541738322
#define FB_LANGUAGE_RIANG 541149522
#define FB_LANGUAGE_RIPUARIAN 541610827
#define FB_LANGUAGE_RITARUNGO 542394706
#define FB_LANGUAGE_ROHINGYA 541542482
#define FB_LANGUAGE_ROMANIAN 541937490
#define FB_LANGUAGE_ROMANSH 542330194
#define FB_LANGUAGE_ROMANY 542723922
#define FB_LANGUAGE_ROTUMAN 541938770
#define FB_LANGUAGE_RUNDI 542004562
#define FB_LANGUAGE_RUSSIAN 542332242
#define FB_LANGUAGE_RUSSIAN_BURIAT 542458450
#define FB_LANGUAGE_RUSYN 542724946
#define FB_LANGUAGE_SADRI 541344083
#define FB_LANGUAGE_SAKHA 541802841
#define FB_LANGUAGE_SAMOAN 542068051
#define FB_LANGUAGE_SAMOGITIAN 542328659
#define FB_LANGUAGE_SAN_BLAS_KUNA 541807939
#define FB_LANGUAGE_SANGO 542066515
#define FB_LANGUAGE_SANSKRIT 541999443
#define FB_LANGUAGE_SANTALI 542392659
#define FB_LANGUAGE_SARAIKI 541807187
#define FB_LANGUAGE_SARDINIAN 541348435
#define FB_LANGUAGE_SASAK 542327123
#define FB_LANGUAGE_SATERLAND_FRISIAN 542200915
#define FB_LANGUAGE_SAYISI 542720339
#define FB_LANGUAGE_SCOTS 541672275
#define FB_LANGUAGE_SCOTTISH_GAELIC 541409607
#define FB_LANGUAGE_SEKOTA 541738323
#define FB_LANGUAGE_SELKUP 541869395
#define FB_LANGUAGE_SENA 541150803
#define FB_LANGUAGE_SENECA 541410643
#define FB_LANGUAGE_SERBIAN 541217363
#define FB_LANGUAGE_SERER 542265939
#define FB_LANGUAGE_SGAW_KAREN 542593867
#define FB_LANGUAGE_SHAN 542001235
#define FB_LANGUAGE_SHONA 541150803
#define FB_LANGUAGE_SIBE 541215059
#define FB_LANGUAGE_SICILIAN 541999955
#define FB_LANGUAGE_SIDAMO 541346131
#define FB_LANGUAGE_SILESIAN 541874771
#define FB_LANGUAGE_SILTE_GURAGE 541542739
#define FB_LANGUAGE_SINDHI 541347411
#define FB_LANGUAGE_SINHALA 541609555
#define FB_LANGUAGE_SKOLT_SAMI 542329683
#define FB_LANGUAGE_SLAVEY 541150291
#define FB_LANGUAGE_SLOVAK 542722899
#define FB_LANGUAGE_SLOVENIAN 542526547
#define FB_LANGUAGE_SMALL_FLOWERY_MIAO 541935187
#define FB_LANGUAGE_SODO_GURAGE 541544275
#define FB_LANGUAGE_SOGA 541544280
#define FB_LANGUAGE_SOMALI 541871443
#define FB_LANGUAGE_SONGE 542134099
#define FB_LANGUAGE_SONINKE 541806163
#define FB_LANGUAGE_SOUTH_SLAVEY 541872979
#define FB_LANGUAGE_SOUTHERN_KIWAI 541346379
#define FB_LANGUAGE_SOUTHERN_SAMI 541938515
#define FB_LANGUAGE_SOUTHERN_SOTHO 542396243
#define FB_LANGUAGE_SPANISH 542135109
#define FB_LANGUAGE_STANDARD_MOROCCAN_TAMAZIGHT 541607770
#define FB_LANGUAGE_STRAITS_SALISH 542266451
#define FB_LANGUAGE_SUKUMA 541807955
#define FB_LANGUAGE_SUNDANESE 542004563
#define FB_LANGUAGE_SURI 542266707
#define FB_LANGUAGE_SUTU 542398547
#define FB_LANGUAGE_SVAN 541152851
#define FB_LANGUAGE_SWADAYA_ARAMAIC 541153107
#define FB_LANGUAGE_SWAHILI 541808467
#define FB_LANGUAGE_SWATI 542791507
#define FB_LANGUAGE_SWEDISH 541414995
#define FB_LANGUAGE_SYLHETI 541874515
#define FB_LANGUAGE_SYRIAC 542267731
#define FB_LANGUAGE_SYRIAC_EASTERN 1314019667
#define FB_LANGUAGE_SYRIAC_ESTRANGELA 1163024723
#define FB_LANGUAGE_SYRIAC_WESTERN 1246910803
#define FB_LANGUAGE_TABASARAN 541213012
#define FB_LANGUAGE_TACHELHIT 541673555
#define FB_LANGUAGE_TAGALOG 541869908
#define FB_LANGUAGE_TAHAGGART_TAMAHAQ 542525524
#define FB_LANGUAGE_TAHITIAN 542394452
#define FB_LANGUAGE_TAI_LAING 541870676
#define FB_LANGUAGE_TAJIKI 541737300
#define FB_LANGUAGE_TALYSH 542723156
#define FB_LANGUAGE_TAMASHEK 541609300
#define FB_LANGUAGE_TAMASHEQ 542196052
#define FB_LANGUAGE_TAMAZIGHT 541940308
#define FB_LANGUAGE_TAMIL 541933908
#define FB_LANGUAGE_TARIFIT 541477202
#define FB_LANGUAGE_TATAR 542392660
#define FB_LANGUAGE_TAWALLAMMAT_TAMAJAQ 542200916
#define FB_LANGUAGE_TAY 542792020
#define FB_LANGUAGE_TAYART_TAMAJEQ 542787668
#define FB_LANGUAGE_TELUGU 541869396
#define FB_LANGUAGE_TEMNE 542002516
#define FB_LANGUAGE_TETUM 542393684
#define FB_LANGUAGE_TH_CREE 542262100
#define FB_LANGUAGE_THAI 541149268
#define FB_LANGUAGE_THAILAND_MON 1414418253
#define FB_LANGUAGE_THOMPSON 542132308
#define FB_LANGUAGE_TIBETAN 541215060
#define FB_LANGUAGE_TIGRE 542263124
#define FB_LANGUAGE_TIGRINYA 542721876
#define FB_LANGUAGE_TIV 542525780
#define FB_LANGUAGE_TLINGIT 541674580
#define FB_LANGUAGE_TOBO 542523988
#define FB_LANGUAGE_TODO 541347668
#define FB_LANGUAGE_TOK_PISIN 541675604
#define FB_LANGUAGE_TOMA 809783124
#define FB_LANGUAGE_TONGA 541544020
#define FB_LANGUAGE_TONGAN 542000980
#define FB_LANGUAGE_TORKI 541219393
#define FB_LANGUAGE_TSHANGLA 541741908
#define FB_LANGUAGE_TSONGA 541545300
#define FB_LANGUAGE_TSWANA 541150804
#define FB_LANGUAGE_TULU 541873492
#define FB_LANGUAGE_TUMBUKA 541939028
#define FB_LANGUAGE_TUNDRA_ENETS 541412948
#define FB_LANGUAGE_TURKISH 541807188
#define FB_LANGUAGE_TURKMEN 541936468
#define FB_LANGUAGE_TUROYO_ARAMAIC 541152596
#define FB_LANGUAGE_TUSCARORA 542332244
#define FB_LANGUAGE_TUVALU 541873748
#define FB_LANGUAGE_TUVIN 542528852
#define FB_LANGUAGE_TWI 541677396
#define FB_LANGUAGE_TZOTZIL 542071380
#define FB_LANGUAGE_UDI 541672533
#define FB_LANGUAGE_UDMURT 541934677
#define FB_LANGUAGE_UKRAINIAN 542264149
#define FB_LANGUAGE_UMBUNDU 541216085
#define FB_LANGUAGE_UME_SAMI 542460499
#define FB_LANGUAGE_UPPER_SAXON 542464083
#define FB_LANGUAGE_UPPER_SORBIAN 541217621
#define FB_LANGUAGE_URALIC_PHONETIC 542134357
#define FB_LANGUAGE_URDU 541348437
#define FB_LANGUAGE_UYGHUR 541546837
#define FB_LANGUAGE_UZBEK 541219413
#define FB_LANGUAGE_VENDA 542000470
#define FB_LANGUAGE_VENETIAN 541279574
#define FB_LANGUAGE_VIETNAMESE 542394710
#define FB_LANGUAGE_VLAX_ROMANI 542723410
#define FB_LANGUAGE_VOLAPUK 541871958
#define FB_LANGUAGE_VORO 542069334
#define FB_LANGUAGE_WA 538984791
#define FB_LANGUAGE_WACI_GBE 541672279
#define FB_LANGUAGE_WAGDI 541540695
#define FB_LANGUAGE_WAKHI 541868631
#define FB_LANGUAGE_WALLOON 542002263
#define FB_LANGUAGE_WARAY_WARAY 542261591
#define FB_LANGUAGE_WAYANAD_CHETTI 542397507
#define FB_LANGUAGE_WAYUU 541283655
#define FB_LANGUAGE_WELSH 541869399
#define FB_LANGUAGE_WENDAT 542393431
#define FB_LANGUAGE_WEST_CREE 542262103
#define FB_LANGUAGE_WESTERN_CHAM 541149763
#define FB_LANGUAGE_WESTERN_KAYAH 542464331
#define FB_LANGUAGE_WESTERN_PANJABI 541216336
#define FB_LANGUAGE_WESTERN_PWO_KAREN 542070608
#define FB_LANGUAGE_WOLOF 541477975
#define FB_LANGUAGE_WOODS_CREE 542262084
#define FB_LANGUAGE_WUDING_LUQUAN_YI 542201689
#define FB_LANGUAGE_WYANDOT 542005591
#define FB_LANGUAGE_XHOSA 542328920
#define FB_LANGUAGE_Y_CREE 542262105
#define FB_LANGUAGE_YAO 542064985
#define FB_LANGUAGE_YAPESE 542130521
#define FB_LANGUAGE_YI_CLASSIC 541280601
#define FB_LANGUAGE_YI_MODERN 541935961
#define FB_LANGUAGE_YIDDISH 541673802
#define FB_LANGUAGE_YORUBA 541147737
#define FB_LANGUAGE_ZAMBOANGA_CHAVACANO 541803075
#define FB_LANGUAGE_ZANDE 541347418
#define FB_LANGUAGE_ZARMA 542263876
#define FB_LANGUAGE_ZAZAKI 541153882
#define FB_LANGUAGE_ZEALANDIC 541148506
#define FB_LANGUAGE_ZHUANG 541149274
#define FB_LANGUAGE_ZULU 541873498

typedef uint32_t fb_Text_Direction;
#define FB_TEXT_DIRECTION_DONT_KNOW 0
#define FB_TEXT_DIRECTION_LEFT_TO_RIGHT 1
#define FB_TEXT_DIRECTION_RIGHT_TO_LEFT 2

typedef struct fb_Line_Height fb_Line_Height;
typedef uint8_t fb_Line_Height_Kind;
#define FB_LINE_HEIGHT_KIND_PERCENTAGE 0
#define FB_LINE_HEIGHT_KIND_FIXED 1

struct fb_Line_Height {
    fb_Line_Height_Kind kind;
    union {
    float percentage;
    float fixed;
    };
};
_Static_assert(sizeof(fb_Line_Height) == 8, "fb_Line_Height");
_Static_assert(offsetof(fb_Line_Height, kind) == 0, "fb_Line_Height.kind");

typedef uint8_t fb_Text_Wrapping;
#define FB_TEXT_WRAPPING_WORD 0
#define FB_TEXT_WRAPPING_CHARACTER 1
#define FB_TEXT_WRAPPING_NONE 2

typedef uint8_t fb_Cursor;
#define FB_CURSOR_DEFAULT 0
#define FB_CURSOR_TEXT 1
#define FB_CURSOR_POINTER 2
#define FB_CURSOR_WAIT 3
#define FB_CURSOR_PROGRESS 4
#define FB_CURSOR_CROSSHAIR 5
#define FB_CURSOR_HELP 6
#define FB_CURSOR_NOT_ALLOWED 7
#define FB_CURSOR_MOVE 8
#define FB_CURSOR_EW_RESIZE 9
#define FB_CURSOR_NS_RESIZE 10
#define FB_CURSOR_NWSE_RESIZE 11
#define FB_CURSOR_NESW_RESIZE 12

typedef uint8_t fb_Overflow;
#define FB_OVERFLOW_VISIBLE 0
#define FB_OVERFLOW_WRAP 1

typedef struct fb_Placement fb_Placement;
typedef uint8_t fb_Placement_Kind;
#define FB_PLACEMENT_KIND_FLOW 0
#define FB_PLACEMENT_KIND_FIXED 1
#define FB_PLACEMENT_KIND_RELATIVE 2

typedef uint8_t fb_Corner;
#define FB_CORNER_TOP_LEFT 0
#define FB_CORNER_TOP_RIGHT 1
#define FB_CORNER_BOTTOM_LEFT 2
#define FB_CORNER_BOTTOM_RIGHT 3

struct fb_Placement {
    fb_Placement_Kind kind;
    fb_Corner corner;
    union {
    fb_Vector2 fixed;
    fb_Vector2 relative;
    };
};
_Static_assert(sizeof(fb_Placement) == 12, "fb_Placement");
_Static_assert(offsetof(fb_Placement, kind) == 0, "fb_Placement.kind");
_Static_assert(offsetof(fb_Placement, corner) == 1, "fb_Placement.corner");

typedef struct fb_Sizing fb_Sizing;
typedef uint8_t fb_Sizing_Kind;
#define FB_SIZING_KIND_FIT 0
#define FB_SIZING_KIND_FIXED 1
#define FB_SIZING_KIND_GROW 2

struct fb_Sizing {
    fb_Sizing_Kind kind;
    union {
    float fixed;
    float ratio;
    float grow;
    };
};
_Static_assert(sizeof(fb_Sizing) == 8, "fb_Sizing");
_Static_assert(offsetof(fb_Sizing, kind) == 0, "fb_Sizing.kind");

typedef uint8_t fb_Direction;
#define FB_DIRECTION_HORIZONTAL 0
#define FB_DIRECTION_VERTICAL 1

typedef uint8_t fb_Alignment;
#define FB_ALIGNMENT_START 0
#define FB_ALIGNMENT_CENTER 1
#define FB_ALIGNMENT_END 2

struct fb_Complete_Style {
    fb_Background background;
    fb_Vector4 color;
    float border_radius;
    fb_Vector4 border_color;
    fb_Sides border_width;
    fb_Border_Style border_style;
    fb_Shadow shadow;
    fb_Font * font;
    fb_Language language;
    fb_Text_Direction text_direction;
    uint16_t font_weight;
    float font_size;
    fb_Line_Height line_height;
    fb_Text_Wrapping text_wrapping;
    fb_Cursor cursor;
    fb_Overflow overflow;
    fb_Placement placement;
    uint16_t z_index;
    float min_width;
    float max_width;
    fb_Sizing width;
    float max_height;
    float min_height;
    fb_Sizing height;
    fb_Vector2 translate;
    fb_Vector2 children_offset;
    fb_Sides padding;
    fb_Sides margin;
    fb_Direction direction;
    fb_Alignment x_justification;
    fb_Alignment y_justification;
};
_Static_assert(sizeof(fb_Complete_Style) == 264, "fb_Complete_Style");
_Static_assert(offsetof(fb_Complete_Style, background) == 0, "fb_Complete_Style.background");
_Static_assert(offsetof(fb_Complete_Style, color) == 32, "fb_Complete_Style.color");
_Static_assert(offsetof(fb_Complete_Style, border_radius) == 48, "fb_Complete_Style.border_radius");
_Static_assert(offsetof(fb_Complete_Style, border_color) == 52, "fb_Complete_Style.border_color");
_Static_assert(offsetof(fb_Complete_Style, border_width) == 68, "fb_Complete_Style.border_width");
_Static_assert(offsetof(fb_Complete_Style, border_style) == 84, "fb_Complete_Style.border_style");
_Static_assert(offsetof(fb_Complete_Style, shadow) == 88, "fb_Complete_Style.shadow");
_Static_assert(offsetof(fb_Complete_Style, font) == 128, "fb_Complete_Style.font");
_Static_assert(offsetof(fb_Complete_Style, language) == 136, "fb_Complete_Style.language");
_Static_assert(offsetof(fb_Complete_Style, text_direction) == 140, "fb_Complete_Style.text_direction");
_Static_assert(offsetof(fb_Complete_Style, font_weight) == 144, "fb_Complete_Style.font_weight");
_Static_assert(offsetof(fb_Complete_Style, font_size) == 148, "fb_Complete_Style.font_size");
_Static_assert(offsetof(fb_Complete_Style, line_height) == 152, "fb_Complete_Style.line_height");
_Static_assert(offsetof(fb_Complete_Style, text_wrapping) == 160, "fb_Complete_Style.text_wrapping");
_Static_assert(offsetof(fb_Complete_Style, cursor) == 161, "fb_Complete_Style.cursor");
_Static_assert(offsetof(fb_Complete_Style, overflow) == 162, "fb_Complete_Style.overflow");
_Static_assert(offsetof(fb_Complete_Style, placement) == 164, "fb_Complete_Style.placement");
_Static_assert(offsetof(fb_Complete_Style, z_index) == 176, "fb_Complete_Style.z_index");
_Static_assert(offsetof(fb_Complete_Style, min_width) == 180, "fb_Complete_Style.min_width");
_Static_assert(offsetof(fb_Complete_Style, max_width) == 184, "fb_Complete_Style.max_width");
_Static_assert(offsetof(fb_Complete_Style, width) == 188, "fb_Complete_Style.width");
_Static_assert(offsetof(fb_Complete_Style, max_height) == 196, "fb_Complete_Style.max_height");
_Static_assert(offsetof(fb_Complete_Style, min_height) == 200, "fb_Complete_Style.min_height");
_Static_assert(offsetof(fb_Complete_Style, height) == 204, "fb_Complete_Style.height");
_Static_assert(offsetof(fb_Complete_Style, translate) == 212, "fb_Complete_Style.translate");
_Static_assert(offsetof(fb_Complete_Style, children_offset) == 220, "fb_Complete_Style.children_offset");
_Static_assert(offsetof(fb_Complete_Style, padding) == 228, "fb_Complete_Style.padding");
_Static_assert(offsetof(fb_Complete_Style, margin) == 244, "fb_Complete_Style.margin");
_Static_assert(offsetof(fb_Complete_Style, direction) == 260, "fb_Complete_Style.direction");
_Static_assert(offsetof(fb_Complete_Style, x_justification) == 261, "fb_Complete_Style.x_justification");
_Static_assert(offsetof(fb_Complete_Style, y_justification) == 262, "fb_Complete_Style.y_justification");

typedef struct fb_Style fb_Style;
struct fb_Style {
    fb_Background background;
    fb_Vector4 color;
    float border_radius;
    fb_Vector4 border_color;
    fb_Sides border_width;
    fb_Border_Style border_style;
    fb_Shadow shadow;
    fb_Font * font;
    uint16_t font_weight;
    float font_size;
    fb_Line_Height line_height;
    fb_Text_Wrapping text_wrapping;
    fb_Language language;
    fb_Text_Direction text_direction;
    fb_Cursor cursor;
    fb_Overflow overflow;
    fb_Placement placement;
    uint16_t z_index;
    float min_width;
    float max_width;
    fb_Sizing width;
    float min_height;
    float max_height;
    fb_Sizing height;
    fb_Vector2 translate;
    fb_Vector2 children_offset;
    fb_Sides padding;
    fb_Sides margin;
    fb_Alignment x_justification;
    fb_Alignment y_justification;
    fb_Direction direction;
};
_Static_assert(sizeof(fb_Style) == 272, "fb_Style");
_Static_assert(offsetof(fb_Style, background) == 0, "fb_Style.background");
_Static_assert(offsetof(fb_Style, color) == 32, "fb_Style.color");
_Static_assert(offsetof(fb_Style, border_radius) == 48, "fb_Style.border_radius");
_Static_assert(offsetof(fb_Style, border_color) == 52, "fb_Style.border_color");
_Static_assert(offsetof(fb_Style, border_width) == 68, "fb_Style.border_width");
_Static_assert(offsetof(fb_Style, border_style) == 84, "fb_Style.border_style");
_Static_assert(offsetof(fb_Style, shadow) == 88, "fb_Style.shadow");
_Static_assert(offsetof(fb_Style, font) == 128, "fb_Style.font");
_Static_assert(offsetof(fb_Style, font_weight) == 136, "fb_Style.font_weight");
_Static_assert(offsetof(fb_Style, font_size) == 140, "fb_Style.font_size");
_Static_assert(offsetof(fb_Style, line_height) == 144, "fb_Style.line_height");
_Static_assert(offsetof(fb_Style, text_wrapping) == 152, "fb_Style.text_wrapping");
_Static_assert(offsetof(fb_Style, language) == 156, "fb_Style.language");
_Static_assert(offsetof(fb_Style, text_direction) == 160, "fb_Style.text_direction");
_Static_assert(offsetof(fb_Style, cursor) == 164, "fb_Style.cursor");
_Static_assert(offsetof(fb_Style, overflow) == 165, "fb_Style.overflow");
_Static_assert(offsetof(fb_Style, placement) == 168, "fb_Style.placement");
_Static_assert(offsetof(fb_Style, z_index) == 180, "fb_Style.z_index");
_Static_assert(offsetof(fb_Style, min_width) == 184, "fb_Style.min_width");
_Static_assert(offsetof(fb_Style, max_width) == 188, "fb_Style.max_width");
_Static_assert(offsetof(fb_Style, width) == 192, "fb_Style.width");
_Static_assert(offsetof(fb_Style, min_height) == 200, "fb_Style.min_height");
_Static_assert(offsetof(fb_Style, max_height) == 204, "fb_Style.max_height");
_Static_assert(offsetof(fb_Style, height) == 208, "fb_Style.height");
_Static_assert(offsetof(fb_Style, translate) == 216, "fb_Style.translate");
_Static_assert(offsetof(fb_Style, children_offset) == 224, "fb_Style.children_offset");
_Static_assert(offsetof(fb_Style, padding) == 232, "fb_Style.padding");
_Static_assert(offsetof(fb_Style, margin) == 248, "fb_Style.margin");
_Static_assert(offsetof(fb_Style, x_justification) == 264, "fb_Style.x_justification");
_Static_assert(offsetof(fb_Style, y_justification) == 265, "fb_Style.y_justification");
_Static_assert(offsetof(fb_Style, direction) == 266, "fb_Style.direction");

typedef struct fb_Wayland_EGL_Backend fb_Wayland_EGL_Backend;
typedef struct fb_Allocator fb_Allocator;
struct fb_Allocator {
    _Alignas(8) uint8_t proc[8];
    void * data;
};
_Static_assert(sizeof(fb_Allocator) == 16, "fb_Allocator");
_Static_assert(offsetof(fb_Allocator, proc) == 0, "fb_Allocator.proc");
_Static_assert(offsetof(fb_Allocator, data) == 8, "fb_Allocator.data");

typedef struct { int64_t count; uint64_t *data; int64_t allocated; fb_Allocator allocator; } fb_Array_uint64_t;

typedef struct fb_Wayland_Connection fb_Wayland_Connection;
typedef struct fb_pollfd fb_pollfd;
struct fb_pollfd {
    int32_t fd;
    int16_t events;
    int16_t revents;
};
_Static_assert(sizeof(fb_pollfd) == 8, "fb_pollfd");
_Static_assert(offsetof(fb_pollfd, fd) == 0, "fb_pollfd.fd");
_Static_assert(offsetof(fb_pollfd, events) == 4, "fb_pollfd.events");
_Static_assert(offsetof(fb_pollfd, revents) == 6, "fb_pollfd.revents");

typedef struct { int64_t count; uint8_t *data; } fb_View_uint8_t;

typedef struct { int64_t count; int32_t *data; } fb_View_int32_t;

typedef uint32_t fb_Interface_Id;
#define FB_INTERFACE_ID_WL_DISPLAY 0
#define FB_INTERFACE_ID_WL_REGISTRY 1
#define FB_INTERFACE_ID_WL_CALLBACK 2
#define FB_INTERFACE_ID_WL_COMPOSITOR 3
#define FB_INTERFACE_ID_WL_SHM_POOL 4
#define FB_INTERFACE_ID_WL_SHM 5
#define FB_INTERFACE_ID_WL_BUFFER 6
#define FB_INTERFACE_ID_WL_DATA_OFFER 7
#define FB_INTERFACE_ID_WL_DATA_SOURCE 8
#define FB_INTERFACE_ID_WL_DATA_DEVICE 9
#define FB_INTERFACE_ID_WL_DATA_DEVICE_MANAGER 10
#define FB_INTERFACE_ID_WL_SHELL 11
#define FB_INTERFACE_ID_WL_SHELL_SURFACE 12
#define FB_INTERFACE_ID_WL_SURFACE 13
#define FB_INTERFACE_ID_WL_SEAT 14
#define FB_INTERFACE_ID_WL_POINTER 15
#define FB_INTERFACE_ID_WL_KEYBOARD 16
#define FB_INTERFACE_ID_WL_TOUCH 17
#define FB_INTERFACE_ID_WL_OUTPUT 18
#define FB_INTERFACE_ID_WL_REGION 19
#define FB_INTERFACE_ID_WL_SUBCOMPOSITOR 20
#define FB_INTERFACE_ID_WL_SUBSURFACE 21
#define FB_INTERFACE_ID_WL_FIXES 22
#define FB_INTERFACE_ID_XDG_WM_BASE 23
#define FB_INTERFACE_ID_XDG_POSITIONER 24
#define FB_INTERFACE_ID_XDG_SURFACE 25
#define FB_INTERFACE_ID_XDG_TOPLEVEL 26
#define FB_INTERFACE_ID_XDG_POPUP 27
#define FB_INTERFACE_ID_ZWP_LINUX_DMABUF_V1 28
#define FB_INTERFACE_ID_ZWP_LINUX_BUFFER_PARAMS_V1 29
#define FB_INTERFACE_ID_ZWP_LINUX_DMABUF_FEEDBACK_V1 30
#define FB_INTERFACE_ID_WP_VIEWPORTER 31
#define FB_INTERFACE_ID_WP_VIEWPORT 32
#define FB_INTERFACE_ID_WP_FRACTIONAL_SCALE_MANAGER_V1 33
#define FB_INTERFACE_ID_WP_FRACTIONAL_SCALE_V1 34
#define FB_INTERFACE_ID_WP_CURSOR_SHAPE_MANAGER_V1 35
#define FB_INTERFACE_ID_WP_CURSOR_SHAPE_DEVICE_V1 36

typedef struct { int64_t count; fb_Interface_Id *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Interface_Id;

typedef struct { int64_t count; int64_t *data; int64_t allocated; fb_Allocator allocator; } fb_Array_int64_t;

struct fb_Wayland_Connection {
    int32_t fd;
    fb_pollfd polling_fd;
    uint32_t wl_compositor_id;
    uint32_t wl_data_device_id;
    uint32_t wl_data_device_manager_id;
    uint32_t wl_display_id;
    uint32_t wl_keyboard_id;
    uint32_t wl_pointer_id;
    uint32_t wl_registry_id;
    uint32_t wl_seat_id;
    uint32_t wp_cursor_shape_device_id;
    uint32_t wp_cursor_shape_manager_id;
    uint32_t wp_fractional_scale_manager_id;
    uint32_t wp_viewporter_id;
    uint32_t xdg_wm_base_id;
    uint32_t zwp_dmabuf_id;
    void * xkb;
    void * keymap;
    void * key_state;
    void * compose_table;
    void * compose_state;
    uint8_t reading_buffer[4096];
    fb_View_uint8_t pending_reads;
    int32_t reading_fds_buffer[8];
    fb_View_int32_t pending_read_fds;
    fb_Array_Interface_Id client_object_interfaces;
    fb_Array_int64_t free_client_object_interface_ids;
    fb_Array_Interface_Id server_object_interfaces;
};
_Static_assert(sizeof(fb_Wayland_Connection) == 4392, "fb_Wayland_Connection");
_Static_assert(offsetof(fb_Wayland_Connection, fd) == 0, "fb_Wayland_Connection.fd");
_Static_assert(offsetof(fb_Wayland_Connection, polling_fd) == 4, "fb_Wayland_Connection.polling_fd");
_Static_assert(offsetof(fb_Wayland_Connection, wl_compositor_id) == 12, "fb_Wayland_Connection.wl_compositor_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_data_device_id) == 16, "fb_Wayland_Connection.wl_data_device_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_data_device_manager_id) == 20, "fb_Wayland_Connection.wl_data_device_manager_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_display_id) == 24, "fb_Wayland_Connection.wl_display_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_keyboard_id) == 28, "fb_Wayland_Connection.wl_keyboard_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_pointer_id) == 32, "fb_Wayland_Connection.wl_pointer_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_registry_id) == 36, "fb_Wayland_Connection.wl_registry_id");
_Static_assert(offsetof(fb_Wayland_Connection, wl_seat_id) == 40, "fb_Wayland_Connection.wl_seat_id");
_Static_assert(offsetof(fb_Wayland_Connection, wp_cursor_shape_device_id) == 44, "fb_Wayland_Connection.wp_cursor_shape_device_id");
_Static_assert(offsetof(fb_Wayland_Connection, wp_cursor_shape_manager_id) == 48, "fb_Wayland_Connection.wp_cursor_shape_manager_id");
_Static_assert(offsetof(fb_Wayland_Connection, wp_fractional_scale_manager_id) == 52, "fb_Wayland_Connection.wp_fractional_scale_manager_id");
_Static_assert(offsetof(fb_Wayland_Connection, wp_viewporter_id) == 56, "fb_Wayland_Connection.wp_viewporter_id");
_Static_assert(offsetof(fb_Wayland_Connection, xdg_wm_base_id) == 60, "fb_Wayland_Connection.xdg_wm_base_id");
_Static_assert(offsetof(fb_Wayland_Connection, zwp_dmabuf_id) == 64, "fb_Wayland_Connection.zwp_dmabuf_id");
_Static_assert(offsetof(fb_Wayland_Connection, xkb) == 72, "fb_Wayland_Connection.xkb");
_Static_assert(offsetof(fb_Wayland_Connection, keymap) == 80, "fb_Wayland_Connection.keymap");
_Static_assert(offsetof(fb_Wayland_Connection, key_state) == 88, "fb_Wayland_Connection.key_state");
_Static_assert(offsetof(fb_Wayland_Connection, compose_table) == 96, "fb_Wayland_Connection.compose_table");
_Static_assert(offsetof(fb_Wayland_Connection, compose_state) == 104, "fb_Wayland_Connection.compose_state");
_Static_assert(offsetof(fb_Wayland_Connection, reading_buffer) == 112, "fb_Wayland_Connection.reading_buffer");
_Static_assert(offsetof(fb_Wayland_Connection, pending_reads) == 4208, "fb_Wayland_Connection.pending_reads");
_Static_assert(offsetof(fb_Wayland_Connection, reading_fds_buffer) == 4224, "fb_Wayland_Connection.reading_fds_buffer");
_Static_assert(offsetof(fb_Wayland_Connection, pending_read_fds) == 4256, "fb_Wayland_Connection.pending_read_fds");
_Static_assert(offsetof(fb_Wayland_Connection, client_object_interfaces) == 4272, "fb_Wayland_Connection.client_object_interfaces");
_Static_assert(offsetof(fb_Wayland_Connection, free_client_object_interface_ids) == 4312, "fb_Wayland_Connection.free_client_object_interface_ids");
_Static_assert(offsetof(fb_Wayland_Connection, server_object_interfaces) == 4352, "fb_Wayland_Connection.server_object_interfaces");

struct fb_Wayland_EGL_Backend {
    void * egl_display;
    void * egl_context;
    int32_t dri_fd;
    void * device;
    uint32_t clipboard_selection_serial;
    fb_String clipboard_text_buffer;
    _Bool clipboard_mime_is_text;
    uint32_t clipboard_wl_data_source_id;
    fb_String clipboard_text;
    fb_Array_uint64_t dmabuf_modifiers;
    fb_Wayland_Connection connection;
};
_Static_assert(sizeof(fb_Wayland_EGL_Backend) == 4512, "fb_Wayland_EGL_Backend");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, egl_display) == 0, "fb_Wayland_EGL_Backend.egl_display");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, egl_context) == 8, "fb_Wayland_EGL_Backend.egl_context");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, dri_fd) == 16, "fb_Wayland_EGL_Backend.dri_fd");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, device) == 24, "fb_Wayland_EGL_Backend.device");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, clipboard_selection_serial) == 32, "fb_Wayland_EGL_Backend.clipboard_selection_serial");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, clipboard_text_buffer) == 40, "fb_Wayland_EGL_Backend.clipboard_text_buffer");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, clipboard_mime_is_text) == 56, "fb_Wayland_EGL_Backend.clipboard_mime_is_text");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, clipboard_wl_data_source_id) == 60, "fb_Wayland_EGL_Backend.clipboard_wl_data_source_id");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, clipboard_text) == 64, "fb_Wayland_EGL_Backend.clipboard_text");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, dmabuf_modifiers) == 80, "fb_Wayland_EGL_Backend.dmabuf_modifiers");
_Static_assert(offsetof(fb_Wayland_EGL_Backend, connection) == 120, "fb_Wayland_EGL_Backend.connection");

typedef struct fb_Base_Style fb_Base_Style;
struct fb_Base_Style {
    fb_Font * font;
    fb_Language language;
    fb_Text_Direction text_direction;
    fb_Vector4 color;
    float font_size;
    uint16_t font_weight;
    fb_Line_Height line_height;
    fb_Text_Wrapping text_wrapping;
    fb_Cursor cursor;
};
_Static_assert(sizeof(fb_Base_Style) == 56, "fb_Base_Style");
_Static_assert(offsetof(fb_Base_Style, font) == 0, "fb_Base_Style.font");
_Static_assert(offsetof(fb_Base_Style, language) == 8, "fb_Base_Style.language");
_Static_assert(offsetof(fb_Base_Style, text_direction) == 12, "fb_Base_Style.text_direction");
_Static_assert(offsetof(fb_Base_Style, color) == 16, "fb_Base_Style.color");
_Static_assert(offsetof(fb_Base_Style, font_size) == 32, "fb_Base_Style.font_size");
_Static_assert(offsetof(fb_Base_Style, font_weight) == 36, "fb_Base_Style.font_weight");
_Static_assert(offsetof(fb_Base_Style, line_height) == 40, "fb_Base_Style.line_height");
_Static_assert(offsetof(fb_Base_Style, text_wrapping) == 48, "fb_Base_Style.text_wrapping");
_Static_assert(offsetof(fb_Base_Style, cursor) == 49, "fb_Base_Style.cursor");

typedef struct fb_Node_Opening_Data fb_Node_Opening_Data;
struct fb_Node_Opening_Data {
    int64_t parent_index;
    uint64_t scope_key;
    fb_Base_Style base_style;
    int64_t node_index;
};
_Static_assert(sizeof(fb_Node_Opening_Data) == 80, "fb_Node_Opening_Data");
_Static_assert(offsetof(fb_Node_Opening_Data, parent_index) == 0, "fb_Node_Opening_Data.parent_index");
_Static_assert(offsetof(fb_Node_Opening_Data, scope_key) == 8, "fb_Node_Opening_Data.scope_key");
_Static_assert(offsetof(fb_Node_Opening_Data, base_style) == 16, "fb_Node_Opening_Data.base_style");
_Static_assert(offsetof(fb_Node_Opening_Data, node_index) == 72, "fb_Node_Opening_Data.node_index");

typedef struct fb_Wayland_Event fb_Wayland_Event;
typedef struct fb_Message_Info fb_Message_Info;
struct fb_Message_Info {
    void * type;
    int32_t first_arg;
    int32_t arg_count;
};
_Static_assert(sizeof(fb_Message_Info) == 16, "fb_Message_Info");
_Static_assert(offsetof(fb_Message_Info, type) == 0, "fb_Message_Info.type");
_Static_assert(offsetof(fb_Message_Info, first_arg) == 8, "fb_Message_Info.first_arg");
_Static_assert(offsetof(fb_Message_Info, arg_count) == 12, "fb_Message_Info.arg_count");

struct fb_Wayland_Event {
    _Bool something;
    fb_Message_Info message;
    void * data;
    uint32_t object_id;
};
_Static_assert(sizeof(fb_Wayland_Event) == 40, "fb_Wayland_Event");
_Static_assert(offsetof(fb_Wayland_Event, something) == 0, "fb_Wayland_Event.something");
_Static_assert(offsetof(fb_Wayland_Event, message) == 8, "fb_Wayland_Event.message");
_Static_assert(offsetof(fb_Wayland_Event, data) == 24, "fb_Wayland_Event.data");
_Static_assert(offsetof(fb_Wayland_Event, object_id) == 32, "fb_Wayland_Event.object_id");

typedef struct fb_Forbear fb_Forbear;
typedef struct fb_Node fb_Node;
typedef int64_t fb_Node_Kind;
#define FB_NODE_KIND_ELEMENT 0
#define FB_NODE_KIND_SCOPE 1

typedef struct fb_Glyphs fb_Glyphs;
typedef struct fb_Glyph fb_Glyph;
typedef struct fb_kbts_encode_utf8 fb_kbts_encode_utf8;
struct fb_kbts_encode_utf8 {
    uint8_t Encoded[4];
    int32_t EncodedLength;
    int32_t Valid;
};
_Static_assert(sizeof(fb_kbts_encode_utf8) == 12, "fb_kbts_encode_utf8");
_Static_assert(offsetof(fb_kbts_encode_utf8, Encoded) == 0, "fb_kbts_encode_utf8.Encoded");
_Static_assert(offsetof(fb_kbts_encode_utf8, EncodedLength) == 4, "fb_kbts_encode_utf8.EncodedLength");
_Static_assert(offsetof(fb_kbts_encode_utf8, Valid) == 8, "fb_kbts_encode_utf8.Valid");

struct fb_Glyph {
    int32_t index;
    int64_t index_into_original_text;
    fb_kbts_encode_utf8 utf8;
    _Bool starts_word;
    _Bool can_wrap_before;
    fb_Vector2 position;
    fb_Vector2 advance;
    fb_Vector2 offset;
};
_Static_assert(sizeof(fb_Glyph) == 56, "fb_Glyph");
_Static_assert(offsetof(fb_Glyph, index) == 0, "fb_Glyph.index");
_Static_assert(offsetof(fb_Glyph, index_into_original_text) == 8, "fb_Glyph.index_into_original_text");
_Static_assert(offsetof(fb_Glyph, utf8) == 16, "fb_Glyph.utf8");
_Static_assert(offsetof(fb_Glyph, starts_word) == 28, "fb_Glyph.starts_word");
_Static_assert(offsetof(fb_Glyph, can_wrap_before) == 29, "fb_Glyph.can_wrap_before");
_Static_assert(offsetof(fb_Glyph, position) == 32, "fb_Glyph.position");
_Static_assert(offsetof(fb_Glyph, advance) == 40, "fb_Glyph.advance");
_Static_assert(offsetof(fb_Glyph, offset) == 48, "fb_Glyph.offset");

typedef struct { int64_t count; fb_Glyph *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Glyph;

struct fb_Glyphs {
    uint64_t hash;
    int32_t length;
    fb_Array_Glyph array;
    fb_Array_int64_t pre_break_indices;
    float ascent;
    float line_height;
    fb_Vector2 min_size;
    fb_Vector2 max_size;
};
_Static_assert(sizeof(fb_Glyphs) == 120, "fb_Glyphs");
_Static_assert(offsetof(fb_Glyphs, hash) == 0, "fb_Glyphs.hash");
_Static_assert(offsetof(fb_Glyphs, length) == 8, "fb_Glyphs.length");
_Static_assert(offsetof(fb_Glyphs, array) == 16, "fb_Glyphs.array");
_Static_assert(offsetof(fb_Glyphs, pre_break_indices) == 56, "fb_Glyphs.pre_break_indices");
_Static_assert(offsetof(fb_Glyphs, ascent) == 96, "fb_Glyphs.ascent");
_Static_assert(offsetof(fb_Glyphs, line_height) == 100, "fb_Glyphs.line_height");
_Static_assert(offsetof(fb_Glyphs, min_size) == 104, "fb_Glyphs.min_size");
_Static_assert(offsetof(fb_Glyphs, max_size) == 112, "fb_Glyphs.max_size");

struct fb_Node {
    fb_Node_Kind kind;
    fb_Vector2 size;
    fb_Vector2 position;
    fb_Vector2 min_size;
    fb_Vector2 max_size;
    uint16_t z;
    int64_t first_child;
    int64_t last_child;
    int64_t next_sibling;
    int64_t previous_sibling;
    int64_t parent;
    fb_Glyphs glyphs;
    fb_Complete_Style style;
    fb_Vector2 content_size;
    fb_Vector4 clipping_rectangle;
    int64_t state_offset;
    int64_t state_size;
    int64_t pool_slot;
    uint64_t key;
    void * tree;
};
_Static_assert(sizeof(fb_Node) == 536, "fb_Node");
_Static_assert(offsetof(fb_Node, kind) == 0, "fb_Node.kind");
_Static_assert(offsetof(fb_Node, size) == 8, "fb_Node.size");
_Static_assert(offsetof(fb_Node, position) == 16, "fb_Node.position");
_Static_assert(offsetof(fb_Node, min_size) == 24, "fb_Node.min_size");
_Static_assert(offsetof(fb_Node, max_size) == 32, "fb_Node.max_size");
_Static_assert(offsetof(fb_Node, z) == 40, "fb_Node.z");
_Static_assert(offsetof(fb_Node, first_child) == 48, "fb_Node.first_child");
_Static_assert(offsetof(fb_Node, last_child) == 56, "fb_Node.last_child");
_Static_assert(offsetof(fb_Node, next_sibling) == 64, "fb_Node.next_sibling");
_Static_assert(offsetof(fb_Node, previous_sibling) == 72, "fb_Node.previous_sibling");
_Static_assert(offsetof(fb_Node, parent) == 80, "fb_Node.parent");
_Static_assert(offsetof(fb_Node, glyphs) == 88, "fb_Node.glyphs");
_Static_assert(offsetof(fb_Node, style) == 208, "fb_Node.style");
_Static_assert(offsetof(fb_Node, content_size) == 472, "fb_Node.content_size");
_Static_assert(offsetof(fb_Node, clipping_rectangle) == 480, "fb_Node.clipping_rectangle");
_Static_assert(offsetof(fb_Node, state_offset) == 496, "fb_Node.state_offset");
_Static_assert(offsetof(fb_Node, state_size) == 504, "fb_Node.state_size");
_Static_assert(offsetof(fb_Node, pool_slot) == 512, "fb_Node.pool_slot");
_Static_assert(offsetof(fb_Node, key) == 520, "fb_Node.key");
_Static_assert(offsetof(fb_Node, tree) == 528, "fb_Node.tree");

typedef struct { int64_t count; fb_Node *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Node;

typedef struct fb_Node_Measurement fb_Node_Measurement;
struct fb_Node_Measurement {
    fb_Vector2 size;
    fb_Vector2 content_size;
    fb_Vector2 position;
    fb_Vector4 clipping_rectangle;
    int64_t state_offset;
    int64_t state_size;
    int64_t pool_slot;
    uint64_t key;
};
_Static_assert(sizeof(fb_Node_Measurement) == 72, "fb_Node_Measurement");
_Static_assert(offsetof(fb_Node_Measurement, size) == 0, "fb_Node_Measurement.size");
_Static_assert(offsetof(fb_Node_Measurement, content_size) == 8, "fb_Node_Measurement.content_size");
_Static_assert(offsetof(fb_Node_Measurement, position) == 16, "fb_Node_Measurement.position");
_Static_assert(offsetof(fb_Node_Measurement, clipping_rectangle) == 24, "fb_Node_Measurement.clipping_rectangle");
_Static_assert(offsetof(fb_Node_Measurement, state_offset) == 40, "fb_Node_Measurement.state_offset");
_Static_assert(offsetof(fb_Node_Measurement, state_size) == 48, "fb_Node_Measurement.state_size");
_Static_assert(offsetof(fb_Node_Measurement, pool_slot) == 56, "fb_Node_Measurement.pool_slot");
_Static_assert(offsetof(fb_Node_Measurement, key) == 64, "fb_Node_Measurement.key");

typedef struct { int64_t count; fb_Node_Measurement *data; int64_t allocated; fb_Allocator allocator; } fb_Array_Node_Measurement;

typedef struct fb_Pool_Slot fb_Pool_Slot;
struct fb_Pool_Slot {
    _Alignas(8) uint8_t pool[40];
    fb_Allocator allocator;
    int64_t last_frame;
    _Bool used;
};
_Static_assert(sizeof(fb_Pool_Slot) == 72, "fb_Pool_Slot");
_Static_assert(offsetof(fb_Pool_Slot, pool) == 0, "fb_Pool_Slot.pool");
_Static_assert(offsetof(fb_Pool_Slot, allocator) == 40, "fb_Pool_Slot.allocator");
_Static_assert(offsetof(fb_Pool_Slot, last_frame) == 56, "fb_Pool_Slot.last_frame");
_Static_assert(offsetof(fb_Pool_Slot, used) == 64, "fb_Pool_Slot.used");

typedef struct fb_Glyph_Atlas fb_Glyph_Atlas;
struct fb_Glyph_Atlas {
    uint32_t texture;
    _Alignas(8) uint8_t table[56];
    int32_t cursor_x;
    int32_t cursor_y;
    int32_t row_height;
    int32_t size;
    double scale;
};
_Static_assert(sizeof(fb_Glyph_Atlas) == 88, "fb_Glyph_Atlas");
_Static_assert(offsetof(fb_Glyph_Atlas, texture) == 0, "fb_Glyph_Atlas.texture");
_Static_assert(offsetof(fb_Glyph_Atlas, table) == 8, "fb_Glyph_Atlas.table");
_Static_assert(offsetof(fb_Glyph_Atlas, cursor_x) == 64, "fb_Glyph_Atlas.cursor_x");
_Static_assert(offsetof(fb_Glyph_Atlas, cursor_y) == 68, "fb_Glyph_Atlas.cursor_y");
_Static_assert(offsetof(fb_Glyph_Atlas, row_height) == 72, "fb_Glyph_Atlas.row_height");
_Static_assert(offsetof(fb_Glyph_Atlas, size) == 76, "fb_Glyph_Atlas.size");
_Static_assert(offsetof(fb_Glyph_Atlas, scale) == 80, "fb_Glyph_Atlas.scale");

typedef struct fb_Wayland_EGL_Window fb_Wayland_EGL_Window;
typedef uint32_t fb_Preferred_Theme;
#define FB_PREFERRED_THEME_DARK 0
#define FB_PREFERRED_THEME_LIGHT 1

typedef struct fb_Keyboard_State fb_Keyboard_State;
typedef uint32_t fb_Key;
#define FB_KEY_A 97
#define FB_KEY_B 98
#define FB_KEY_C 99
#define FB_KEY_D 100
#define FB_KEY_E 101
#define FB_KEY_F 102
#define FB_KEY_G 103
#define FB_KEY_H 104
#define FB_KEY_I 105
#define FB_KEY_J 106
#define FB_KEY_K 107
#define FB_KEY_L 108
#define FB_KEY_M 109
#define FB_KEY_N 110
#define FB_KEY_O 111
#define FB_KEY_P 112
#define FB_KEY_Q 113
#define FB_KEY_R 114
#define FB_KEY_S 115
#define FB_KEY_T 116
#define FB_KEY_U 117
#define FB_KEY_V 118
#define FB_KEY_W 119
#define FB_KEY_X 120
#define FB_KEY_Y 121
#define FB_KEY_Z 122
#define FB_KEY_DIGIT_0 48
#define FB_KEY_DIGIT_1 49
#define FB_KEY_DIGIT_2 50
#define FB_KEY_DIGIT_3 51
#define FB_KEY_DIGIT_4 52
#define FB_KEY_DIGIT_5 53
#define FB_KEY_DIGIT_6 54
#define FB_KEY_DIGIT_7 55
#define FB_KEY_DIGIT_8 56
#define FB_KEY_DIGIT_9 57
#define FB_KEY_SPACE 32
#define FB_KEY_EXCLAMATION 33
#define FB_KEY_QUOTE 34
#define FB_KEY_HASH 35
#define FB_KEY_DOLLAR 36
#define FB_KEY_PERCENT 37
#define FB_KEY_AMPERSAND 38
#define FB_KEY_APOSTROPHE 39
#define FB_KEY_PARENTHESIS_LEFT 40
#define FB_KEY_PARENTHESIS_RIGHT 41
#define FB_KEY_ASTERISK 42
#define FB_KEY_PLUS 43
#define FB_KEY_COMMA 44
#define FB_KEY_MINUS 45
#define FB_KEY_PERIOD 46
#define FB_KEY_SLASH 47
#define FB_KEY_COLON 58
#define FB_KEY_SEMICOLON 59
#define FB_KEY_LESS 60
#define FB_KEY_EQUAL 61
#define FB_KEY_GREATER 62
#define FB_KEY_QUESTION 63
#define FB_KEY_AT 64
#define FB_KEY_BRACKET_LEFT 91
#define FB_KEY_BACKSLASH 92
#define FB_KEY_BRACKET_RIGHT 93
#define FB_KEY_CARET 94
#define FB_KEY_UNDERSCORE 95
#define FB_KEY_GRAVE 96
#define FB_KEY_BRACE_LEFT 123
#define FB_KEY_PIPE 124
#define FB_KEY_BRACE_RIGHT 125
#define FB_KEY_TILDE 126
#define FB_KEY_ESCAPE 1114112
#define FB_KEY_ENTER 1114113
#define FB_KEY_TAB 1114114
#define FB_KEY_BACKSPACE 1114115
#define FB_KEY_DELETE 1114116
#define FB_KEY_INSERT 1114117
#define FB_KEY_ARROW_LEFT 1114118
#define FB_KEY_ARROW_RIGHT 1114119
#define FB_KEY_ARROW_UP 1114120
#define FB_KEY_ARROW_DOWN 1114121
#define FB_KEY_HOME 1114122
#define FB_KEY_END 1114123
#define FB_KEY_PAGE_UP 1114124
#define FB_KEY_PAGE_DOWN 1114125
#define FB_KEY_F1 1114126
#define FB_KEY_F2 1114127
#define FB_KEY_F3 1114128
#define FB_KEY_F4 1114129
#define FB_KEY_F5 1114130
#define FB_KEY_F6 1114131
#define FB_KEY_F7 1114132
#define FB_KEY_F8 1114133
#define FB_KEY_F9 1114134
#define FB_KEY_F10 1114135
#define FB_KEY_F11 1114136
#define FB_KEY_F12 1114137
#define FB_KEY_F13 1114138
#define FB_KEY_F14 1114139
#define FB_KEY_F15 1114140
#define FB_KEY_F16 1114141
#define FB_KEY_F17 1114142
#define FB_KEY_F18 1114143
#define FB_KEY_F19 1114144
#define FB_KEY_F20 1114145
#define FB_KEY_SHIFT_LEFT 1114146
#define FB_KEY_SHIFT_RIGHT 1114147
#define FB_KEY_CONTROL_LEFT 1114148
#define FB_KEY_CONTROL_RIGHT 1114149
#define FB_KEY_ALT_LEFT 1114150
#define FB_KEY_ALT_RIGHT 1114151
#define FB_KEY_SUPER_LEFT 1114152
#define FB_KEY_SUPER_RIGHT 1114153
#define FB_KEY_CAPS_LOCK 1114154
#define FB_KEY_FUNCTION 1114155
#define FB_KEY_VOLUME_UP 1114156
#define FB_KEY_VOLUME_DOWN 1114157
#define FB_KEY_VOLUME_MUTE 1114158
#define FB_KEY_CONTEXT_MENU 1114159
#define FB_KEY_HELP 1114160

typedef struct fb_Key_Event fb_Key_Event;
typedef int64_t fb_Key_Event_Kind;
#define FB_KEY_EVENT_KIND_REPEATED 0
#define FB_KEY_EVENT_KIND_RELEASED 1
#define FB_KEY_EVENT_KIND_PRESSED 2

struct fb_Key_Event {
    fb_Key_Event_Kind kind;
    fb_Key key;
};
_Static_assert(sizeof(fb_Key_Event) == 16, "fb_Key_Event");
_Static_assert(offsetof(fb_Key_Event, kind) == 0, "fb_Key_Event.kind");
_Static_assert(offsetof(fb_Key_Event, key) == 8, "fb_Key_Event.key");

typedef struct { int64_t count; fb_Key_Event *data; } fb_View_Key_Event;

struct fb_Keyboard_State {
    uint32_t serial;
    _Bool inside;
    fb_Key repeating_key;
    uint32_t repeating_key_code;
    double next_repeat;
    int32_t repeat_rate;
    int32_t repeat_delay;
    fb_Key_Event events_buffer[96];
    fb_View_Key_Event events;
    fb_Key held[776];
    _Bool simulated;
};
_Static_assert(sizeof(fb_Keyboard_State) == 4696, "fb_Keyboard_State");
_Static_assert(offsetof(fb_Keyboard_State, serial) == 0, "fb_Keyboard_State.serial");
_Static_assert(offsetof(fb_Keyboard_State, inside) == 4, "fb_Keyboard_State.inside");
_Static_assert(offsetof(fb_Keyboard_State, repeating_key) == 8, "fb_Keyboard_State.repeating_key");
_Static_assert(offsetof(fb_Keyboard_State, repeating_key_code) == 12, "fb_Keyboard_State.repeating_key_code");
_Static_assert(offsetof(fb_Keyboard_State, next_repeat) == 16, "fb_Keyboard_State.next_repeat");
_Static_assert(offsetof(fb_Keyboard_State, repeat_rate) == 24, "fb_Keyboard_State.repeat_rate");
_Static_assert(offsetof(fb_Keyboard_State, repeat_delay) == 28, "fb_Keyboard_State.repeat_delay");
_Static_assert(offsetof(fb_Keyboard_State, events_buffer) == 32, "fb_Keyboard_State.events_buffer");
_Static_assert(offsetof(fb_Keyboard_State, events) == 1568, "fb_Keyboard_State.events");
_Static_assert(offsetof(fb_Keyboard_State, held) == 1584, "fb_Keyboard_State.held");
_Static_assert(offsetof(fb_Keyboard_State, simulated) == 4688, "fb_Keyboard_State.simulated");

typedef struct fb_Mouse_State fb_Mouse_State;
struct fb_Mouse_State {
    uint32_t serial;
    _Bool inside;
    fb_Vector2 position;
    fb_Vector2 scroll_delta;
    fb_Cursor cursor;
    fb_Vector2 press_position[8];
    _Bool pressed[8];
    _Bool released[8];
    _Bool held[8];
};
_Static_assert(sizeof(fb_Mouse_State) == 116, "fb_Mouse_State");
_Static_assert(offsetof(fb_Mouse_State, serial) == 0, "fb_Mouse_State.serial");
_Static_assert(offsetof(fb_Mouse_State, inside) == 4, "fb_Mouse_State.inside");
_Static_assert(offsetof(fb_Mouse_State, position) == 8, "fb_Mouse_State.position");
_Static_assert(offsetof(fb_Mouse_State, scroll_delta) == 16, "fb_Mouse_State.scroll_delta");
_Static_assert(offsetof(fb_Mouse_State, cursor) == 24, "fb_Mouse_State.cursor");
_Static_assert(offsetof(fb_Mouse_State, press_position) == 28, "fb_Mouse_State.press_position");
_Static_assert(offsetof(fb_Mouse_State, pressed) == 92, "fb_Mouse_State.pressed");
_Static_assert(offsetof(fb_Mouse_State, released) == 100, "fb_Mouse_State.released");
_Static_assert(offsetof(fb_Mouse_State, held) == 108, "fb_Mouse_State.held");

typedef struct fb_Wayland_EGL_Buffer fb_Wayland_EGL_Buffer;
struct fb_Wayland_EGL_Buffer {
    uint32_t wl_buffer_id;
    void * gbm_buffer_object;
    void * egl_image;
    uint32_t texture;
    uint32_t fbo;
    _Bool busy;
};
_Static_assert(sizeof(fb_Wayland_EGL_Buffer) == 40, "fb_Wayland_EGL_Buffer");
_Static_assert(offsetof(fb_Wayland_EGL_Buffer, wl_buffer_id) == 0, "fb_Wayland_EGL_Buffer.wl_buffer_id");
_Static_assert(offsetof(fb_Wayland_EGL_Buffer, gbm_buffer_object) == 8, "fb_Wayland_EGL_Buffer.gbm_buffer_object");
_Static_assert(offsetof(fb_Wayland_EGL_Buffer, egl_image) == 16, "fb_Wayland_EGL_Buffer.egl_image");
_Static_assert(offsetof(fb_Wayland_EGL_Buffer, texture) == 24, "fb_Wayland_EGL_Buffer.texture");
_Static_assert(offsetof(fb_Wayland_EGL_Buffer, fbo) == 28, "fb_Wayland_EGL_Buffer.fbo");
_Static_assert(offsetof(fb_Wayland_EGL_Buffer, busy) == 32, "fb_Wayland_EGL_Buffer.busy");

struct fb_Wayland_EGL_Window {
    uint32_t wl_surface_id;
    uint32_t wl_buffer_params_id;
    uint32_t wl_frame_callback_id;
    uint32_t wp_viewport_id;
    uint32_t wp_fractional_scale_id;
    uint32_t xdg_surface_id;
    uint32_t xdg_toplevel_id;
    int32_t width;
    int32_t logical_width;
    int32_t height;
    int32_t logical_height;
    double scale;
    fb_Preferred_Theme theme;
    uint8_t text_buffer[4096];
    fb_String text;
    fb_Keyboard_State keyboard_state;
    fb_Mouse_State mouse_state;
    fb_Vector2 scroll_delta;
    fb_Wayland_EGL_Buffer buffers[2];
    int64_t current;
    _Bool waiting_for_vblank;
    _Bool running;
};
_Static_assert(sizeof(fb_Wayland_EGL_Window) == 9096, "fb_Wayland_EGL_Window");
_Static_assert(offsetof(fb_Wayland_EGL_Window, wl_surface_id) == 0, "fb_Wayland_EGL_Window.wl_surface_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, wl_buffer_params_id) == 4, "fb_Wayland_EGL_Window.wl_buffer_params_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, wl_frame_callback_id) == 8, "fb_Wayland_EGL_Window.wl_frame_callback_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, wp_viewport_id) == 12, "fb_Wayland_EGL_Window.wp_viewport_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, wp_fractional_scale_id) == 16, "fb_Wayland_EGL_Window.wp_fractional_scale_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, xdg_surface_id) == 20, "fb_Wayland_EGL_Window.xdg_surface_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, xdg_toplevel_id) == 24, "fb_Wayland_EGL_Window.xdg_toplevel_id");
_Static_assert(offsetof(fb_Wayland_EGL_Window, width) == 28, "fb_Wayland_EGL_Window.width");
_Static_assert(offsetof(fb_Wayland_EGL_Window, logical_width) == 32, "fb_Wayland_EGL_Window.logical_width");
_Static_assert(offsetof(fb_Wayland_EGL_Window, height) == 36, "fb_Wayland_EGL_Window.height");
_Static_assert(offsetof(fb_Wayland_EGL_Window, logical_height) == 40, "fb_Wayland_EGL_Window.logical_height");
_Static_assert(offsetof(fb_Wayland_EGL_Window, scale) == 48, "fb_Wayland_EGL_Window.scale");
_Static_assert(offsetof(fb_Wayland_EGL_Window, theme) == 56, "fb_Wayland_EGL_Window.theme");
_Static_assert(offsetof(fb_Wayland_EGL_Window, text_buffer) == 60, "fb_Wayland_EGL_Window.text_buffer");
_Static_assert(offsetof(fb_Wayland_EGL_Window, text) == 4160, "fb_Wayland_EGL_Window.text");
_Static_assert(offsetof(fb_Wayland_EGL_Window, keyboard_state) == 4176, "fb_Wayland_EGL_Window.keyboard_state");
_Static_assert(offsetof(fb_Wayland_EGL_Window, mouse_state) == 8872, "fb_Wayland_EGL_Window.mouse_state");
_Static_assert(offsetof(fb_Wayland_EGL_Window, scroll_delta) == 8988, "fb_Wayland_EGL_Window.scroll_delta");
_Static_assert(offsetof(fb_Wayland_EGL_Window, buffers) == 9000, "fb_Wayland_EGL_Window.buffers");
_Static_assert(offsetof(fb_Wayland_EGL_Window, current) == 9080, "fb_Wayland_EGL_Window.current");
_Static_assert(offsetof(fb_Wayland_EGL_Window, waiting_for_vblank) == 9088, "fb_Wayland_EGL_Window.waiting_for_vblank");
_Static_assert(offsetof(fb_Wayland_EGL_Window, running) == 9089, "fb_Wayland_EGL_Window.running");

struct fb_Forbear {
    fb_Array_Node node_tree;
    fb_Array_Node_Measurement measurements;
    int64_t frame;
    float delta_time;
    double last_frame_time;
    fb_Allocator persistent_allocator;
    int64_t parent_index;
    void * state_buffers;
    fb_Pool_Slot pool_slots[256];
    uint64_t scope_key;
    fb_Base_Style base_style;
    uint16_t font_counter;
    int64_t state_current;
    int64_t state_used;
    void * freetype_library;
    void * shaping_context;
    uint32_t shader_program;
    uint32_t shader_vao;
    uint32_t node_vbo;
    fb_Glyph_Atlas glyph_atlas;
    fb_Wayland_EGL_Window * window;
    fb_Wayland_EGL_Backend * backend;
};
_Static_assert(sizeof(fb_Forbear) == 18792, "fb_Forbear");
_Static_assert(offsetof(fb_Forbear, node_tree) == 0, "fb_Forbear.node_tree");
_Static_assert(offsetof(fb_Forbear, measurements) == 40, "fb_Forbear.measurements");
_Static_assert(offsetof(fb_Forbear, frame) == 80, "fb_Forbear.frame");
_Static_assert(offsetof(fb_Forbear, delta_time) == 88, "fb_Forbear.delta_time");
_Static_assert(offsetof(fb_Forbear, last_frame_time) == 96, "fb_Forbear.last_frame_time");
_Static_assert(offsetof(fb_Forbear, persistent_allocator) == 104, "fb_Forbear.persistent_allocator");
_Static_assert(offsetof(fb_Forbear, parent_index) == 120, "fb_Forbear.parent_index");
_Static_assert(offsetof(fb_Forbear, state_buffers) == 128, "fb_Forbear.state_buffers");
_Static_assert(offsetof(fb_Forbear, pool_slots) == 136, "fb_Forbear.pool_slots");
_Static_assert(offsetof(fb_Forbear, scope_key) == 18568, "fb_Forbear.scope_key");
_Static_assert(offsetof(fb_Forbear, base_style) == 18576, "fb_Forbear.base_style");
_Static_assert(offsetof(fb_Forbear, font_counter) == 18632, "fb_Forbear.font_counter");
_Static_assert(offsetof(fb_Forbear, state_current) == 18640, "fb_Forbear.state_current");
_Static_assert(offsetof(fb_Forbear, state_used) == 18648, "fb_Forbear.state_used");
_Static_assert(offsetof(fb_Forbear, freetype_library) == 18656, "fb_Forbear.freetype_library");
_Static_assert(offsetof(fb_Forbear, shaping_context) == 18664, "fb_Forbear.shaping_context");
_Static_assert(offsetof(fb_Forbear, shader_program) == 18672, "fb_Forbear.shader_program");
_Static_assert(offsetof(fb_Forbear, shader_vao) == 18676, "fb_Forbear.shader_vao");
_Static_assert(offsetof(fb_Forbear, node_vbo) == 18680, "fb_Forbear.node_vbo");
_Static_assert(offsetof(fb_Forbear, glyph_atlas) == 18688, "fb_Forbear.glyph_atlas");
_Static_assert(offsetof(fb_Forbear, window) == 18776, "fb_Forbear.window");
_Static_assert(offsetof(fb_Forbear, backend) == 18784, "fb_Forbear.backend");

typedef int64_t fb_Mouse_Button;
#define FB_MOUSE_BUTTON_LEFT 0
#define FB_MOUSE_BUTTON_RIGHT 1
#define FB_MOUSE_BUTTON_MIDDLE 2
#define FB_MOUSE_BUTTON_SIDE 3
#define FB_MOUSE_BUTTON_EXTRA 4
#define FB_MOUSE_BUTTON_FORWARD 5
#define FB_MOUSE_BUTTON_BACK 6
#define FB_MOUSE_BUTTON_TASK 7

typedef fb_Wayland_EGL_Window fb_Window;
typedef fb_Wayland_EGL_Backend fb_Backend;

fb_String fb_get_text_input(void);
void fb_copy_to_clipboard(const char * text);
fb_String fb_get_clipboard_text(void);
_Bool fb_is_mouse_inside(void);
double fb_get_last_frame_time(void);
float fb_get_delta_time(void);
typedef float (*fb_Proc_float_float)(float);
float fb_use_transition_f(float value, float duration, fb_Proc_float_float easing);
void fb_text(const char * content, const char * key);
void * fb_node_realloc(void * memory, int64_t size, int64_t old_size);
void * fb_node_alloc(int64_t size);
void * fb_frame_realloc(void * memory, int64_t size, int64_t old_size);
void * fb_frame_alloc(int64_t size);
void * fb_state(int64_t size, void * initial);
void fb_prepare_for_next_frame(void);
void fb_layout(void);
void __jai_runtime_fini(void * _context);
void fb_init_forbear(fb_Forbear * forbear, fb_Wayland_EGL_Backend * program_backend, fb_Wayland_EGL_Window * program_window, fb_Base_Style program_base_style);
void fb_init_backend(fb_Wayland_EGL_Backend * backend);
void fb_init_window(fb_Wayland_EGL_Backend * backend, fb_Wayland_EGL_Window * window, double width, double height, const char * title, double min_width, double min_height, double max_width, double max_height);
fb_Wayland_Event fb_next_event(fb_Wayland_Connection * connection, _Bool wait);
_Bool fb_can_draw(fb_Wayland_EGL_Window window);
void fb_update_backend(fb_Wayland_EGL_Backend * backend, fb_Wayland_Event event);
void fb_update_window(fb_Wayland_EGL_Backend * backend, fb_Wayland_EGL_Window * window, fb_Wayland_Event event);
fb_Font fb_create_font(fb_String memory);
void fb_init_font(fb_Font * font);
void fb_draw(fb_Vector4 clearing_color);
fb_Node_Opening_Data fb_open_element(fb_Style style, const char * key);
void fb_close_element(fb_Node_Opening_Data data);
fb_Node_Opening_Data fb_open_scope(const char * key);
void fb_close_scope(fb_Node_Opening_Data data);
void fb_stext(fb_Style style, const char * content, const char * key);
fb_Direction fb_opposite(fb_Direction direction);
fb_Sizing fb_fit(void);
fb_Sizing fb_fixed(float value);
fb_Sizing fb_grow(float value);
fb_Sides fb_all_sides(float value);
fb_Sides fb_in_line_sides(float value);
fb_Sides fb_with_in_line_sides(fb_Sides sides, float value);
fb_Sides fb_block_sides(float value);
fb_Sides fb_with_block_sides(fb_Sides sides, float value);
fb_Sides fb_left_sides(float value);
fb_Sides fb_with_left_sides(fb_Sides sides, float value);
fb_Sides fb_right_sides(float value);
fb_Sides fb_with_right_sides(fb_Sides sides, float value);
fb_Sides fb_top_sides(float value);
fb_Sides fb_with_top_sides(fb_Sides sides, float value);
fb_Sides fb_bottom_sides(float value);
fb_Sides fb_with_bottom_sides(fb_Sides sides, float value);
fb_Line_Height fb_line_height_percentage(float value);
fb_Line_Height fb_line_height_fixed(float value);
fb_Vector2 fb_use_transition_v2(fb_Vector2 value, float duration, fb_Proc_float_float easing);
fb_Vector3 fb_use_transition_v3(fb_Vector3 value, float duration, fb_Proc_float_float easing);
fb_Vector4 fb_use_transition_v4(fb_Vector4 value, float duration, fb_Proc_float_float easing);
void fb_schedule_scroll(fb_Scrolling_State * state, fb_Vector2 position, _Bool animate);
void fb_use_scrolling(fb_Scrolling_State * state);
fb_Base_Style fb_from(fb_Complete_Style style);
fb_Vector2 fb_angle(float degrees);
fb_Vector2 fb_to_top(void);
fb_Vector2 fb_to_bottom(void);
fb_Vector2 fb_to_left(void);
fb_Vector2 fb_to_right(void);
fb_Vector2 fb_to_top_left(void);
fb_Vector2 fb_to_top_right(void);
fb_Vector2 fb_to_bottom_left(void);
fb_Vector2 fb_to_bottom_right(void);
fb_Background fb_color(fb_Vector4 value);
fb_Background fb_gradient(fb_Linear_Gradient value);
fb_Vector4 fb_rgb(float r, float g, float b);
fb_Vector4 fb_rgba(float r, float g, float b, float a);
fb_Placement fb_flow(void);
fb_Placement fb_fixed_placement(fb_Vector2 value, fb_Corner corner);
fb_Placement fb_relative(fb_Vector2 value, fb_Corner corner);
fb_Style fb_overwrite(fb_Style overwritten, fb_Style overwriter);
void fb_complete_with(fb_Style style, fb_Base_Style base, fb_Complete_Style * out);
_Bool fb_get_measurement(int64_t node_index, _Bool include_scopes, fb_Node_Measurement * out);
fb_Node * fb_get_node(int64_t node_index);
fb_Vector2 fb_get_viewport_size(void);
fb_Preferred_Theme fb_get_preferred_theme(void);
void fb_set_cursor(fb_Cursor cursor);
fb_Vector2 fb_get_mouse_position(void);
fb_Vector2 fb_get_scroll_delta(void);
fb_Vector2 fb_get_press_position(fb_Mouse_Button button);
_Bool fb_is_dragging(fb_Mouse_Button button);
_Bool fb_is_mouse_held(fb_Mouse_Button button);
_Bool fb_on_mouse_down(fb_Mouse_Button button, _Bool check_inside);
_Bool fb_on_mouse_up(fb_Mouse_Button button, _Bool check_inside);
_Bool fb_on_click(fb_Mouse_Button button, _Bool check_inside, _Bool movement_threshold);
_Bool fb_on_key_down(fb_Key key, _Bool on_repeat);
_Bool fb_on_key_up(fb_Key key);
_Bool fb_is_key_held(fb_Key key);
void * __jai_runtime_init(int32_t argc, void * argv);
typedef struct fb_Spring_Config_float fb_Spring_Config_float;
struct fb_Spring_Config_float {
    float stiffness;
    float damping;
    float mass;
    float * current;
};
_Static_assert(sizeof(fb_Spring_Config_float) == 24, "fb_Spring_Config_float");
_Static_assert(offsetof(fb_Spring_Config_float, stiffness) == 0, "fb_Spring_Config_float.stiffness");
_Static_assert(offsetof(fb_Spring_Config_float, damping) == 4, "fb_Spring_Config_float.damping");
_Static_assert(offsetof(fb_Spring_Config_float, mass) == 8, "fb_Spring_Config_float.mass");
_Static_assert(offsetof(fb_Spring_Config_float, current) == 16, "fb_Spring_Config_float.current");

float fb_use_spring_transition_f(float target, fb_Spring_Config_float config);
typedef struct fb_Spring_Config_Vector2 fb_Spring_Config_Vector2;
struct fb_Spring_Config_Vector2 {
    float stiffness;
    float damping;
    float mass;
    fb_Vector2 * current;
};
_Static_assert(sizeof(fb_Spring_Config_Vector2) == 24, "fb_Spring_Config_Vector2");
_Static_assert(offsetof(fb_Spring_Config_Vector2, stiffness) == 0, "fb_Spring_Config_Vector2.stiffness");
_Static_assert(offsetof(fb_Spring_Config_Vector2, damping) == 4, "fb_Spring_Config_Vector2.damping");
_Static_assert(offsetof(fb_Spring_Config_Vector2, mass) == 8, "fb_Spring_Config_Vector2.mass");
_Static_assert(offsetof(fb_Spring_Config_Vector2, current) == 16, "fb_Spring_Config_Vector2.current");

fb_Vector2 fb_use_spring_transition_v2(fb_Vector2 target, fb_Spring_Config_Vector2 config);
typedef struct fb_Spring_Config_Vector3 fb_Spring_Config_Vector3;
struct fb_Spring_Config_Vector3 {
    float stiffness;
    float damping;
    float mass;
    fb_Vector3 * current;
};
_Static_assert(sizeof(fb_Spring_Config_Vector3) == 24, "fb_Spring_Config_Vector3");
_Static_assert(offsetof(fb_Spring_Config_Vector3, stiffness) == 0, "fb_Spring_Config_Vector3.stiffness");
_Static_assert(offsetof(fb_Spring_Config_Vector3, damping) == 4, "fb_Spring_Config_Vector3.damping");
_Static_assert(offsetof(fb_Spring_Config_Vector3, mass) == 8, "fb_Spring_Config_Vector3.mass");
_Static_assert(offsetof(fb_Spring_Config_Vector3, current) == 16, "fb_Spring_Config_Vector3.current");

fb_Vector3 fb_use_spring_transition_v3(fb_Vector3 target, fb_Spring_Config_Vector3 config);
typedef struct fb_Spring_Config_Vector4 fb_Spring_Config_Vector4;
struct fb_Spring_Config_Vector4 {
    float stiffness;
    float damping;
    float mass;
    fb_Vector4 * current;
};
_Static_assert(sizeof(fb_Spring_Config_Vector4) == 24, "fb_Spring_Config_Vector4");
_Static_assert(offsetof(fb_Spring_Config_Vector4, stiffness) == 0, "fb_Spring_Config_Vector4.stiffness");
_Static_assert(offsetof(fb_Spring_Config_Vector4, damping) == 4, "fb_Spring_Config_Vector4.damping");
_Static_assert(offsetof(fb_Spring_Config_Vector4, mass) == 8, "fb_Spring_Config_Vector4.mass");
_Static_assert(offsetof(fb_Spring_Config_Vector4, current) == 16, "fb_Spring_Config_Vector4.current");

fb_Vector4 fb_use_spring_transition_v4(fb_Vector4 target, fb_Spring_Config_Vector4 config);
#endif
#if !defined(_WIN32) && !defined(__linux__) && !defined(__APPLE__)
#error "forbear: unsupported platform"
#endif
// ====== END AUTO GENERATED PORTION ======

#if defined(__clang__)
#define FB_OVERRIDES_BEGIN _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Winitializer-overrides\"")
#define FB_OVERRIDES_END   _Pragma("clang diagnostic pop")
#elif defined(__GNUC__)
#define FB_OVERRIDES_BEGIN _Pragma("GCC diagnostic push") _Pragma("GCC diagnostic ignored \"-Woverride-init\"")
#define FB_OVERRIDES_END   _Pragma("GCC diagnostic pop")
#else
#define FB_OVERRIDES_BEGIN
#define FB_OVERRIDES_END
#endif

#define FB_UNSET 0xFF
#define FB_VECTOR2_NAN { FB_FLOAT32_NAN, FB_FLOAT32_NAN }
#define FB_VECTOR4_NAN { FB_FLOAT32_NAN, FB_FLOAT32_NAN, FB_FLOAT32_NAN, FB_FLOAT32_NAN }
#define FB_SIDES_NAN   { FB_VECTOR2_NAN, FB_VECTOR2_NAN }

#define FB_STYLE(...) \
    FB_OVERRIDES_BEGIN \
    ((fb_Style){ \
        .background      = { .kind = FB_UNSET }, \
        .color           = FB_VECTOR4_NAN, \
        .border_radius   = FB_FLOAT32_NAN, \
        .border_color    = FB_VECTOR4_NAN, \
        .border_width    = FB_SIDES_NAN, \
        .border_style    = FB_UNSET, \
        .shadow          = { \
            .offset      = FB_SIDES_NAN, \
            .blur_radius = FB_FLOAT32_NAN, \
            .spread      = FB_FLOAT32_NAN, \
            .color       = FB_VECTOR4_NAN, \
        }, \
        .font            = NULL, \
        .font_weight     = 0, \
        .font_size       = FB_FLOAT32_NAN, \
        .line_height     = { .kind = FB_UNSET }, \
        .text_wrapping   = FB_UNSET, \
        .language        = FB_UNSET, \
        .text_direction  = FB_UNSET, \
        .cursor          = FB_UNSET, \
        .overflow        = FB_UNSET, \
        .placement       = { .kind = FB_UNSET }, \
        .z_index         = UINT16_MAX, \
        .min_width       = FB_FLOAT32_NAN, \
        .max_width       = FB_FLOAT32_NAN, \
        .width           = { .kind = FB_UNSET }, \
        .min_height      = FB_FLOAT32_NAN, \
        .max_height      = FB_FLOAT32_NAN, \
        .height          = { .kind = FB_UNSET }, \
        .translate       = FB_VECTOR2_NAN, \
        .children_offset = FB_VECTOR2_NAN, \
        .padding         = FB_SIDES_NAN, \
        .margin          = FB_SIDES_NAN, \
        .x_justification = FB_UNSET, \
        .y_justification = FB_UNSET, \
        .direction       = FB_UNSET, \
        __VA_ARGS__ \
    }) \
    FB_OVERRIDES_END

#define FB_STRINGIFY_(x) #x
#define FB_STRINGIFY(x)  FB_STRINGIFY_(x)
#define FB_LOCATION_KEY __FILE__ ":" FB_STRINGIFY(__LINE__) ":" FB_STRINGIFY(__COUNTER__)

#define FB_ELEMENT_KEYED(key, ...) \
    for (int fb_element_latch = 0; fb_element_latch < 1;) \
        for (fb_Node_Opening_Data fb_element_data = fb_open_element(FB_STYLE(__VA_ARGS__), (key)); \
             fb_element_latch < 1; \
             fb_element_latch = 1, fb_close_element(fb_element_data))
#define FB_ELEMENT(...) FB_ELEMENT_KEYED(FB_LOCATION_KEY, __VA_ARGS__)

#define FB_SCOPE_KEYED(key) \
    for (int fb_scope_latch = 0; fb_scope_latch < 1;) \
        for (fb_Node_Opening_Data fb_scope_data = fb_open_scope(key); \
             fb_scope_latch < 1; \
             fb_scope_latch = 1, fb_close_scope(fb_scope_data))
#define FB_SCOPE() FB_SCOPE_KEYED(FB_LOCATION_KEY)

#define FB_STATE(T, ...) ((T *)fb_state(sizeof(T), &(T){ __VA_ARGS__ }))

#define FB_TEXT_KEYED(key, content, ...) fb_stext(FB_STYLE(__VA_ARGS__), (content), (key))
#define FB_TEXT(content, ...)            FB_TEXT_KEYED(FB_LOCATION_KEY, content, __VA_ARGS__)

#define FB_BASE_STYLE(...) \
    FB_OVERRIDES_BEGIN \
    ((fb_Base_Style){ \
        .font           = NULL, \
        .language       = FB_LANGUAGE_DONT_KNOW, \
        .text_direction = FB_TEXT_DIRECTION_DONT_KNOW, \
        .color          = { 1.0f, 1.0f, 1.0f, 1.0f }, \
        .font_size      = 16.0f, \
        .font_weight    = 600, \
        .line_height    = { .kind = FB_LINE_HEIGHT_KIND_PERCENTAGE, .percentage = 1.0f }, \
        .text_wrapping  = FB_TEXT_WRAPPING_WORD, \
        .cursor         = FB_CURSOR_DEFAULT, \
        __VA_ARGS__ \
    }) \
    FB_OVERRIDES_END

#define FB_USE_TRANSITION(value, duration, easing) \
    _Generic((value), \
        float: fb_use_transition_f, \
        fb_Vector2: fb_use_transition_v2, \
        fb_Vector3: fb_use_transition_v3, \
        fb_Vector4: fb_use_transition_v4)(value, duration, easing)

#define FB_USE_SPRING_TRANSITION(target, config) \
    _Generic((target), \
        float: fb_use_spring_transition_f, \
        fb_Vector2: fb_use_spring_transition_v2, \
        fb_Vector3: fb_use_spring_transition_v3, \
        fb_Vector4: fb_use_spring_transition_v4)(target, config)

#define FB_HEX(rrggbb) ((fb_Vector4){ (((rrggbb) >> 16) & 0xFF) / 255.0f, (((rrggbb) >> 8) & 0xFF) / 255.0f, ((rrggbb) & 0xFF) / 255.0f, 1.0f })
#define FB_HEXA(rrggbbaa) ((fb_Vector4){ (((rrggbbaa) >> 24) & 0xFF) / 255.0f, (((rrggbbaa) >> 16) & 0xFF) / 255.0f, (((rrggbbaa) >> 8) & 0xFF) / 255.0f, ((rrggbbaa) & 0xFF) / 255.0f })

#endif
