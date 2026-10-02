
//
// This file was auto-generated using the following command:
//
// jai build.jai
//




#scope_file


#scope_export
//
// This file was auto-generated using the following command:
//
// jai build.jai
//



kbts_s32 :: s32;

kbts_b32 :: s32;

KB_TEXT_SHAPE_POINTER_SIZE :: 8;

KBTS_VARIATION_VALUE_UNSET :: -100000.0;

KBTS_MAXIMUM_RECOMPOSITION_PARENTS :: 19;
KBTS_MAXIMUM_CODEPOINT_SCRIPTS :: 23;

kbts_windows_language_id :: u16;
kbts_windows_language_id_enum :: enum u32 {
    KBTS_WINDOWS_LANGUAGE_ID_AFRIKAANS                           :: 54;
    KBTS_WINDOWS_LANGUAGE_ID_AFRIKAANS_SOUTH_AFRICA              :: 1078;
    KBTS_WINDOWS_LANGUAGE_ID_ALBANIAN                            :: 28;
    KBTS_WINDOWS_LANGUAGE_ID_ALBANIAN_ALBANIA                    :: 1052;
    KBTS_WINDOWS_LANGUAGE_ID_ALSATIAN                            :: 132;
    KBTS_WINDOWS_LANGUAGE_ID_ALSATIAN_FRANCE                     :: 1156;
    KBTS_WINDOWS_LANGUAGE_ID_AMHARIC                             :: 94;
    KBTS_WINDOWS_LANGUAGE_ID_AMHARIC_ETHIOPIA                    :: 1118;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC                              :: 1;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_ALGERIA                      :: 5121;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_BAHRAIN                      :: 15361;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_EGYPT                        :: 3073;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_IRAQ                         :: 2049;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_JORDAN                       :: 11265;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_KUWAIT                       :: 13313;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_LEBANON                      :: 12289;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_LIBYA                        :: 4097;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_MOROCCO                      :: 6145;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_OMAN                         :: 8193;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_QATAR                        :: 16385;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_SAUDI_ARABIA                 :: 1025;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_SYRIA                        :: 10241;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_TUNISIA                      :: 7169;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_UAE                          :: 14337;
    KBTS_WINDOWS_LANGUAGE_ID_ARABIC_YEMEN                        :: 9217;
    KBTS_WINDOWS_LANGUAGE_ID_ARMENIAN                            :: 43;
    KBTS_WINDOWS_LANGUAGE_ID_ARMENIAN_ARMENIA                    :: 1067;
    KBTS_WINDOWS_LANGUAGE_ID_ASSAMESE                            :: 77;
    KBTS_WINDOWS_LANGUAGE_ID_ASSAMESE_INDIA                      :: 1101;
    KBTS_WINDOWS_LANGUAGE_ID_AZERBAIJANI_CYRILLIC                :: 29740;
    KBTS_WINDOWS_LANGUAGE_ID_AZERBAIJANI_CYRILLIC_AZERBAIJAN     :: 2092;
    KBTS_WINDOWS_LANGUAGE_ID_AZERBAIJANI_LATIN                   :: 44;
    KBTS_WINDOWS_LANGUAGE_ID_AZERBAIJANI_LATIN_2                 :: 30764;
    KBTS_WINDOWS_LANGUAGE_ID_AZERBAIJANI_LATIN_AZERBAIJAN        :: 1068;
    KBTS_WINDOWS_LANGUAGE_ID_BANGLA                              :: 69;
    KBTS_WINDOWS_LANGUAGE_ID_BANGLA_BANGLADESH                   :: 2117;
    KBTS_WINDOWS_LANGUAGE_ID_BANGLA_INDIA                        :: 1093;
    KBTS_WINDOWS_LANGUAGE_ID_BASHKIR                             :: 109;
    KBTS_WINDOWS_LANGUAGE_ID_BASHKIR_RUSSIA                      :: 1133;
    KBTS_WINDOWS_LANGUAGE_ID_BASQUE                              :: 45;
    KBTS_WINDOWS_LANGUAGE_ID_BASQUE_SPAIN                        :: 1069;
    KBTS_WINDOWS_LANGUAGE_ID_BELARUSIAN                          :: 35;
    KBTS_WINDOWS_LANGUAGE_ID_BELARUSIAN_BELARUS                  :: 1059;
    KBTS_WINDOWS_LANGUAGE_ID_BOSNIAN_CYRILLIC                    :: 25626;
    KBTS_WINDOWS_LANGUAGE_ID_BOSNIAN_CYRILLIC_BOSNIA_HERZEGOVINA :: 8218;
    KBTS_WINDOWS_LANGUAGE_ID_BOSNIAN_LATIN                       :: 26650;
    KBTS_WINDOWS_LANGUAGE_ID_BOSNIAN_LATIN_2                     :: 30746;
    KBTS_WINDOWS_LANGUAGE_ID_BOSNIAN_LATIN_BOSNIA_HERZEGOVINA    :: 5146;
    KBTS_WINDOWS_LANGUAGE_ID_BRETON                              :: 126;
    KBTS_WINDOWS_LANGUAGE_ID_BRETON_FRANCE                       :: 1150;
    KBTS_WINDOWS_LANGUAGE_ID_BULGARIAN                           :: 2;
    KBTS_WINDOWS_LANGUAGE_ID_BULGARIAN_BULGARIA                  :: 1026;
    KBTS_WINDOWS_LANGUAGE_ID_BURMESE                             :: 85;
    KBTS_WINDOWS_LANGUAGE_ID_BURMESE_MYANMAR                     :: 1109;
    KBTS_WINDOWS_LANGUAGE_ID_CATALAN                             :: 3;
    KBTS_WINDOWS_LANGUAGE_ID_CATALAN_SPAIN                       :: 1027;
    KBTS_WINDOWS_LANGUAGE_ID_CENTRAL_ATLAS_TAMAZIGHT_ARABIC      :: 1119;
    KBTS_WINDOWS_LANGUAGE_ID_CENTRAL_KURDISH                     :: 146;
    KBTS_WINDOWS_LANGUAGE_ID_CENTRAL_KURDISH_2                   :: 31890;
    KBTS_WINDOWS_LANGUAGE_ID_CENTRAL_KURDISH_IRAQ                :: 1170;
    KBTS_WINDOWS_LANGUAGE_ID_CHEROKEE                            :: 92;
    KBTS_WINDOWS_LANGUAGE_ID_CHEROKEE_2                          :: 31836;
    KBTS_WINDOWS_LANGUAGE_ID_CHEROKEE_UNITED_STATES              :: 1116;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_SIMPLIFIED                  :: 4;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_SIMPLIFIED_2                :: 30724;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_SIMPLIFIED_PRC              :: 2052;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_SIMPLIFIED_SINGAPORE        :: 4100;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_TRADITIONAL                 :: 31748;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_TRADITIONAL_HONG_KONG       :: 3076;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_TRADITIONAL_MACAO           :: 5124;
    KBTS_WINDOWS_LANGUAGE_ID_CHINESE_TRADITIONAL_TAIWAN          :: 1028;
    KBTS_WINDOWS_LANGUAGE_ID_CORSICAN                            :: 131;
    KBTS_WINDOWS_LANGUAGE_ID_CORSICAN_FRANCE                     :: 1155;
    KBTS_WINDOWS_LANGUAGE_ID_CROATIAN                            :: 26;
    KBTS_WINDOWS_LANGUAGE_ID_CROATIAN_CROATIA                    :: 1050;
    KBTS_WINDOWS_LANGUAGE_ID_CROATIAN_LATIN_BOSNIA_HERZEGOVINA   :: 4122;
    KBTS_WINDOWS_LANGUAGE_ID_CZECH                               :: 5;
    KBTS_WINDOWS_LANGUAGE_ID_CZECH_CZECHIA                       :: 1029;
    KBTS_WINDOWS_LANGUAGE_ID_DANISH                              :: 6;
    KBTS_WINDOWS_LANGUAGE_ID_DANISH_DENMARK                      :: 1030;
    KBTS_WINDOWS_LANGUAGE_ID_DARI                                :: 140;
    KBTS_WINDOWS_LANGUAGE_ID_DARI_AFGHANISTAN                    :: 1164;
    KBTS_WINDOWS_LANGUAGE_ID_DIVEHI                              :: 101;
    KBTS_WINDOWS_LANGUAGE_ID_DIVEHI_MALDIVES                     :: 1125;
    KBTS_WINDOWS_LANGUAGE_ID_DUTCH                               :: 19;
    KBTS_WINDOWS_LANGUAGE_ID_DUTCH_BELGIUM                       :: 2067;
    KBTS_WINDOWS_LANGUAGE_ID_DUTCH_NETHERLANDS                   :: 1043;
    KBTS_WINDOWS_LANGUAGE_ID_DZONGKHA_BHUTAN                     :: 3153;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH                             :: 9;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_AUSTRALIA                   :: 3081;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_BELIZE                      :: 10249;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_CANADA                      :: 4105;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_CARIBBEAN                   :: 9225;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_HONG_KONG                   :: 15369;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_INDIA                       :: 16393;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_IRELAND                     :: 6153;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_JAMAICA                     :: 8201;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_MALAYSIA                    :: 17417;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_NEW_ZEALAND                 :: 5129;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_PHILIPPINES                 :: 13321;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_SINGAPORE                   :: 18441;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_SOUTH_AFRICA                :: 7177;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_TRINIDAD_TOBAGO             :: 11273;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_UNITED_ARAB_EMIRATES        :: 19465;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_UNITED_KINGDOM              :: 2057;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_UNITED_STATES               :: 1033;
    KBTS_WINDOWS_LANGUAGE_ID_ENGLISH_ZIMBABWE                    :: 12297;
    KBTS_WINDOWS_LANGUAGE_ID_ESTONIAN                            :: 37;
    KBTS_WINDOWS_LANGUAGE_ID_ESTONIAN_ESTONIA                    :: 1061;
    KBTS_WINDOWS_LANGUAGE_ID_FAROESE                             :: 56;
    KBTS_WINDOWS_LANGUAGE_ID_FAROESE_FAROE_ISLANDS               :: 1080;
    KBTS_WINDOWS_LANGUAGE_ID_FILIPINO                            :: 100;
    KBTS_WINDOWS_LANGUAGE_ID_FILIPINO_PHILIPPINES                :: 1124;
    KBTS_WINDOWS_LANGUAGE_ID_FINNISH                             :: 11;
    KBTS_WINDOWS_LANGUAGE_ID_FINNISH_FINLAND                     :: 1035;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH                              :: 12;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_BELGIUM                      :: 2060;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_CAMEROON                     :: 11276;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_CANADA                       :: 3084;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_CARIBBEAN                    :: 7180;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_DRC                          :: 9228;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_COTE_D_IVOIRE                :: 12300;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_FRANCE                       :: 1036;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_HAITI                        :: 15372;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_LUXEMBOURG                   :: 5132;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_MALI                         :: 13324;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_MOROCCO                      :: 14348;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_MONACO                       :: 6156;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_REUNION                      :: 8204;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_SENEGAL                      :: 10252;
    KBTS_WINDOWS_LANGUAGE_ID_FRENCH_SWITZERLAND                  :: 4108;
    KBTS_WINDOWS_LANGUAGE_ID_FRISIAN                             :: 98;
    KBTS_WINDOWS_LANGUAGE_ID_FRISIAN_NETHERLANDS                 :: 1122;
    KBTS_WINDOWS_LANGUAGE_ID_FULAH                               :: 103;
    KBTS_WINDOWS_LANGUAGE_ID_FULAH_LATIN                         :: 31847;
    KBTS_WINDOWS_LANGUAGE_ID_FULAH_NIGERIA                       :: 1127;
    KBTS_WINDOWS_LANGUAGE_ID_FULAH_SENEGAL                       :: 2151;
    KBTS_WINDOWS_LANGUAGE_ID_GALICIAN                            :: 86;
    KBTS_WINDOWS_LANGUAGE_ID_GALICIAN_SPAIN                      :: 1110;
    KBTS_WINDOWS_LANGUAGE_ID_GEORGIAN                            :: 55;
    KBTS_WINDOWS_LANGUAGE_ID_GEORGIAN_GEORGIA                    :: 1079;
    KBTS_WINDOWS_LANGUAGE_ID_GERMAN                              :: 7;
    KBTS_WINDOWS_LANGUAGE_ID_GERMAN_AUSTRIA                      :: 3079;
    KBTS_WINDOWS_LANGUAGE_ID_GERMAN_GERMANY                      :: 1031;
    KBTS_WINDOWS_LANGUAGE_ID_GERMAN_LIECHTENSTEIN                :: 5127;
    KBTS_WINDOWS_LANGUAGE_ID_GERMAN_LUXEMBOURG                   :: 4103;
    KBTS_WINDOWS_LANGUAGE_ID_GERMAN_SWITZERLAND                  :: 2055;
    KBTS_WINDOWS_LANGUAGE_ID_GREEK                               :: 8;
    KBTS_WINDOWS_LANGUAGE_ID_GREEK_GREECE                        :: 1032;
    KBTS_WINDOWS_LANGUAGE_ID_GREENLANDIC                         :: 111;
    KBTS_WINDOWS_LANGUAGE_ID_GREENLANDIC_GREENLAND               :: 1135;
    KBTS_WINDOWS_LANGUAGE_ID_GUARANI                             :: 116;
    KBTS_WINDOWS_LANGUAGE_ID_GUARANI_PARAGUAY                    :: 1140;
    KBTS_WINDOWS_LANGUAGE_ID_GUJARATI                            :: 71;
    KBTS_WINDOWS_LANGUAGE_ID_GUJARATI_INDIA                      :: 1095;
    KBTS_WINDOWS_LANGUAGE_ID_HAUSA                               :: 104;
    KBTS_WINDOWS_LANGUAGE_ID_HAUSA_LATIN                         :: 31848;
    KBTS_WINDOWS_LANGUAGE_ID_HAUSA_NIGERIA                       :: 1128;
    KBTS_WINDOWS_LANGUAGE_ID_HAWAIIAN                            :: 117;
    KBTS_WINDOWS_LANGUAGE_ID_HAWAIIAN_UNITED_STATES              :: 1141;
    KBTS_WINDOWS_LANGUAGE_ID_HEBREW                              :: 13;
    KBTS_WINDOWS_LANGUAGE_ID_HEBREW_ISRAEL                       :: 1037;
    KBTS_WINDOWS_LANGUAGE_ID_HINDI                               :: 57;
    KBTS_WINDOWS_LANGUAGE_ID_HINDI_INDIA                         :: 1081;
    KBTS_WINDOWS_LANGUAGE_ID_HUNGARIAN                           :: 14;
    KBTS_WINDOWS_LANGUAGE_ID_HUNGARIAN_HUNGARY                   :: 1038;
    KBTS_WINDOWS_LANGUAGE_ID_ICELANDIC                           :: 15;
    KBTS_WINDOWS_LANGUAGE_ID_ICELANDIC_ICELAND                   :: 1039;
    KBTS_WINDOWS_LANGUAGE_ID_IGBO                                :: 112;
    KBTS_WINDOWS_LANGUAGE_ID_IGBO_NIGERIA                        :: 1136;
    KBTS_WINDOWS_LANGUAGE_ID_INDONESIAN                          :: 33;
    KBTS_WINDOWS_LANGUAGE_ID_INDONESIAN_INDONESIA                :: 1057;
    KBTS_WINDOWS_LANGUAGE_ID_INUKTITUT                           :: 93;
    KBTS_WINDOWS_LANGUAGE_ID_INUKTITUT_LATIN                     :: 31837;
    KBTS_WINDOWS_LANGUAGE_ID_INUKTITUT_LATIN_CANADA              :: 2141;
    KBTS_WINDOWS_LANGUAGE_ID_INUKTITUT_SYLLABICS                 :: 30813;
    KBTS_WINDOWS_LANGUAGE_ID_INUKTITUT_SYLLABICS_CANADA          :: 1117;
    KBTS_WINDOWS_LANGUAGE_ID_IRISH                               :: 60;
    KBTS_WINDOWS_LANGUAGE_ID_IRISH_IRELAND                       :: 2108;
    KBTS_WINDOWS_LANGUAGE_ID_ITALIAN                             :: 16;
    KBTS_WINDOWS_LANGUAGE_ID_ITALIAN_ITALY                       :: 1040;
    KBTS_WINDOWS_LANGUAGE_ID_ITALIAN_SWITZERLAND                 :: 2064;
    KBTS_WINDOWS_LANGUAGE_ID_JAPANESE                            :: 17;
    KBTS_WINDOWS_LANGUAGE_ID_JAPANESE_JAPAN                      :: 1041;
    KBTS_WINDOWS_LANGUAGE_ID_KANNADA                             :: 75;
    KBTS_WINDOWS_LANGUAGE_ID_KANNADA_INDIA                       :: 1099;
    KBTS_WINDOWS_LANGUAGE_ID_KANURI_LATIN_NIGERIA                :: 1137;
    KBTS_WINDOWS_LANGUAGE_ID_KASHMIRI                            :: 96;
    KBTS_WINDOWS_LANGUAGE_ID_KASHMIRI_PERSO_ARABIC               :: 1120;
    KBTS_WINDOWS_LANGUAGE_ID_KASHMIRI_DEVANAGARI_INDIA           :: 2144;
    KBTS_WINDOWS_LANGUAGE_ID_KAZAKH                              :: 63;
    KBTS_WINDOWS_LANGUAGE_ID_KAZAKH_KAZAKHSTAN                   :: 1087;
    KBTS_WINDOWS_LANGUAGE_ID_KHMER                               :: 83;
    KBTS_WINDOWS_LANGUAGE_ID_KHMER_CAMBODIA                      :: 1107;
    KBTS_WINDOWS_LANGUAGE_ID_KICHE                               :: 134;
    KBTS_WINDOWS_LANGUAGE_ID_KICHE_GUATEMALA                     :: 1158;
    KBTS_WINDOWS_LANGUAGE_ID_KINYARWANDA                         :: 135;
    KBTS_WINDOWS_LANGUAGE_ID_KINYARWANDA_RWANDA                  :: 1159;
    KBTS_WINDOWS_LANGUAGE_ID_KISWAHILI                           :: 65;
    KBTS_WINDOWS_LANGUAGE_ID_KISWAHILI_KENYA                     :: 1089;
    KBTS_WINDOWS_LANGUAGE_ID_KONKANI                             :: 87;
    KBTS_WINDOWS_LANGUAGE_ID_KONKANI_INDIA                       :: 1111;
    KBTS_WINDOWS_LANGUAGE_ID_KOREAN                              :: 18;
    KBTS_WINDOWS_LANGUAGE_ID_KOREAN_KOREA                        :: 1042;
    KBTS_WINDOWS_LANGUAGE_ID_KYRGYZ                              :: 64;
    KBTS_WINDOWS_LANGUAGE_ID_KYRGYZ_KYRGYZSTAN                   :: 1088;
    KBTS_WINDOWS_LANGUAGE_ID_LAO                                 :: 84;
    KBTS_WINDOWS_LANGUAGE_ID_LAO_PDR                             :: 1108;
    KBTS_WINDOWS_LANGUAGE_ID_LATIN_VATICAN                       :: 1142;
    KBTS_WINDOWS_LANGUAGE_ID_LATVIAN                             :: 38;
    KBTS_WINDOWS_LANGUAGE_ID_LATVIAN_LATVIA                      :: 1062;
    KBTS_WINDOWS_LANGUAGE_ID_LITHUANIAN                          :: 39;
    KBTS_WINDOWS_LANGUAGE_ID_LITHUANIAN_LITHUANIA                :: 1063;
    KBTS_WINDOWS_LANGUAGE_ID_LOWER_SORBIAN                       :: 31790;
    KBTS_WINDOWS_LANGUAGE_ID_LOWER_SORBIAN_GERMANY               :: 2094;
    KBTS_WINDOWS_LANGUAGE_ID_LUXEMBOURGISH                       :: 110;
    KBTS_WINDOWS_LANGUAGE_ID_LUXEMBOURGISH_LUXEMBOURG            :: 1134;
    KBTS_WINDOWS_LANGUAGE_ID_MACEDONIAN                          :: 47;
    KBTS_WINDOWS_LANGUAGE_ID_MACEDONIAN_NORTH_MACEDONIA          :: 1071;
    KBTS_WINDOWS_LANGUAGE_ID_MALAY                               :: 62;
    KBTS_WINDOWS_LANGUAGE_ID_MALAY_BRUNEI                        :: 2110;
    KBTS_WINDOWS_LANGUAGE_ID_MALAY_MALAYSIA                      :: 1086;
    KBTS_WINDOWS_LANGUAGE_ID_MALAYALAM                           :: 76;
    KBTS_WINDOWS_LANGUAGE_ID_MALAYALAM_INDIA                     :: 1100;
    KBTS_WINDOWS_LANGUAGE_ID_MALTESE                             :: 58;
    KBTS_WINDOWS_LANGUAGE_ID_MALTESE_MALTA                       :: 1082;
    KBTS_WINDOWS_LANGUAGE_ID_MAORI                               :: 129;
    KBTS_WINDOWS_LANGUAGE_ID_MAORI_NEW_ZEALAND                   :: 1153;
    KBTS_WINDOWS_LANGUAGE_ID_MAPUDUNGUN                          :: 122;
    KBTS_WINDOWS_LANGUAGE_ID_MAPUDUNGUN_CHILE                    :: 1146;
    KBTS_WINDOWS_LANGUAGE_ID_MARATHI                             :: 78;
    KBTS_WINDOWS_LANGUAGE_ID_MARATHI_INDIA                       :: 1102;
    KBTS_WINDOWS_LANGUAGE_ID_MOHAWK                              :: 124;
    KBTS_WINDOWS_LANGUAGE_ID_MOHAWK_CANADA                       :: 1148;
    KBTS_WINDOWS_LANGUAGE_ID_MONGOLIAN                           :: 80;
    KBTS_WINDOWS_LANGUAGE_ID_MONGOLIAN_CYRILLIC                  :: 30800;
    KBTS_WINDOWS_LANGUAGE_ID_MONGOLIAN_CYRILLIC_MONGOLIA         :: 1104;
    KBTS_WINDOWS_LANGUAGE_ID_MONGOLIAN_TRADITIONAL               :: 31824;
    KBTS_WINDOWS_LANGUAGE_ID_MONGOLIAN_TRADITIONAL_PRC           :: 2128;
    KBTS_WINDOWS_LANGUAGE_ID_MONGOLIAN_TRADITIONAL_MONGOLIA      :: 3152;
    KBTS_WINDOWS_LANGUAGE_ID_NEPALI                              :: 97;
    KBTS_WINDOWS_LANGUAGE_ID_NEPALI_INDIA                        :: 2145;
    KBTS_WINDOWS_LANGUAGE_ID_NEPALI_NEPAL                        :: 1121;
    KBTS_WINDOWS_LANGUAGE_ID_NORWEGIAN                           :: 20;
    KBTS_WINDOWS_LANGUAGE_ID_NORWEGIAN_BOKMAL                    :: 31764;
    KBTS_WINDOWS_LANGUAGE_ID_NORWEGIAN_BOKMAL_NORWAY             :: 1044;
    KBTS_WINDOWS_LANGUAGE_ID_NORWEGIAN_NYNORSK                   :: 30740;
    KBTS_WINDOWS_LANGUAGE_ID_NORWEGIAN_NYNORSK_NORWAY            :: 2068;
    KBTS_WINDOWS_LANGUAGE_ID_OCCITAN                             :: 130;
    KBTS_WINDOWS_LANGUAGE_ID_OCCITAN_FRANCE                      :: 1154;
    KBTS_WINDOWS_LANGUAGE_ID_ODIA                                :: 72;
    KBTS_WINDOWS_LANGUAGE_ID_ODIA_INDIA                          :: 1096;
    KBTS_WINDOWS_LANGUAGE_ID_OROMO                               :: 114;
    KBTS_WINDOWS_LANGUAGE_ID_OROMO_ETHIOPIA                      :: 1138;
    KBTS_WINDOWS_LANGUAGE_ID_PASHTO                              :: 99;
    KBTS_WINDOWS_LANGUAGE_ID_PASHTO_AFGHANISTAN                  :: 1123;
    KBTS_WINDOWS_LANGUAGE_ID_PERSIAN                             :: 41;
    KBTS_WINDOWS_LANGUAGE_ID_PERSIAN_IRAN                        :: 1065;
    KBTS_WINDOWS_LANGUAGE_ID_POLISH                              :: 21;
    KBTS_WINDOWS_LANGUAGE_ID_POLISH_POLAND                       :: 1045;
    KBTS_WINDOWS_LANGUAGE_ID_PORTUGUESE                          :: 22;
    KBTS_WINDOWS_LANGUAGE_ID_PORTUGUESE_BRAZIL                   :: 1046;
    KBTS_WINDOWS_LANGUAGE_ID_PORTUGUESE_PORTUGAL                 :: 2070;
    KBTS_WINDOWS_LANGUAGE_ID_PUNJABI                             :: 70;
    KBTS_WINDOWS_LANGUAGE_ID_PUNJABI_ARABIC                      :: 31814;
    KBTS_WINDOWS_LANGUAGE_ID_PUNJABI_INDIA                       :: 1094;
    KBTS_WINDOWS_LANGUAGE_ID_PUNJABI_PAKISTAN                    :: 2118;
    KBTS_WINDOWS_LANGUAGE_ID_QUECHUA                             :: 107;
    KBTS_WINDOWS_LANGUAGE_ID_QUECHUA_BOLIVIA                     :: 1131;
    KBTS_WINDOWS_LANGUAGE_ID_QUECHUA_ECUADOR                     :: 2155;
    KBTS_WINDOWS_LANGUAGE_ID_QUECHUA_PERU                        :: 3179;
    KBTS_WINDOWS_LANGUAGE_ID_ROMANIAN                            :: 24;
    KBTS_WINDOWS_LANGUAGE_ID_ROMANIAN_MOLDOVA                    :: 2072;
    KBTS_WINDOWS_LANGUAGE_ID_ROMANIAN_ROMANIA                    :: 1048;
    KBTS_WINDOWS_LANGUAGE_ID_ROMANSH                             :: 23;
    KBTS_WINDOWS_LANGUAGE_ID_ROMANSH_SWITZERLAND                 :: 1047;
    KBTS_WINDOWS_LANGUAGE_ID_RUSSIAN                             :: 25;
    KBTS_WINDOWS_LANGUAGE_ID_RUSSIAN_MOLDOVA                     :: 2073;
    KBTS_WINDOWS_LANGUAGE_ID_RUSSIAN_RUSSIA                      :: 1049;
    KBTS_WINDOWS_LANGUAGE_ID_SAKHA                               :: 133;
    KBTS_WINDOWS_LANGUAGE_ID_SAKHA_RUSSIA                        :: 1157;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_INARI                          :: 28731;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_INARI_FINLAND                  :: 9275;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_LULE                           :: 31803;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_LULE_NORWAY                    :: 4155;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_LULE_SWEDEN                    :: 5179;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_NORTHERN                       :: 59;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_NORTHERN_FINLAND               :: 3131;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_NORTHERN_NORWAY                :: 1083;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_NORTHERN_SWEDEN                :: 2107;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_SKOLT                          :: 29755;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_SKOLT_FINLAND                  :: 8251;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_SOUTHERN                       :: 30779;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_SOUTHERN_NORWAY                :: 6203;
    KBTS_WINDOWS_LANGUAGE_ID_SAMI_SOUTHERN_SWEDEN                :: 7227;
    KBTS_WINDOWS_LANGUAGE_ID_SANSKRIT                            :: 79;
    KBTS_WINDOWS_LANGUAGE_ID_SANSKRIT_INDIA                      :: 1103;
    KBTS_WINDOWS_LANGUAGE_ID_SCOTTISH_GAELIC                     :: 145;
    KBTS_WINDOWS_LANGUAGE_ID_SCOTTISH_GAELIC_UNITED_KINGDOM      :: 1169;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_CYRILLIC                    :: 27674;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_CYRILLIC_BOSNIA_HERZEGOVINA :: 7194;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_CYRILLIC_MONTENEGRO         :: 12314;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_CYRILLIC_SERBIA             :: 10266;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_CYRILLIC_SERBIA_MONTENEGRO  :: 3098;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_LATIN                       :: 28698;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN                             :: 31770;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_LATIN_BOSNIA_HERZEGOVINA    :: 6170;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_LATIN_MONTENEGRO            :: 11290;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_LATIN_SERBIA                :: 9242;
    KBTS_WINDOWS_LANGUAGE_ID_SERBIAN_LATIN_SERBIA_MONTENEGRO     :: 2074;
    KBTS_WINDOWS_LANGUAGE_ID_SESOTHO_SA_LEBOA                    :: 108;
    KBTS_WINDOWS_LANGUAGE_ID_SESOTHO_SA_LEBOA_SOUTH_AFRICA       :: 1132;
    KBTS_WINDOWS_LANGUAGE_ID_SETSWANA                            :: 50;
    KBTS_WINDOWS_LANGUAGE_ID_SETSWANA_BOTSWANA                   :: 2098;
    KBTS_WINDOWS_LANGUAGE_ID_SETSWANA_SOUTH_AFRICA               :: 1074;
    KBTS_WINDOWS_LANGUAGE_ID_SINDHI                              :: 89;
    KBTS_WINDOWS_LANGUAGE_ID_SINDHI_ARABIC                       :: 31833;
    KBTS_WINDOWS_LANGUAGE_ID_SINDHI_PAKISTAN                     :: 2137;
    KBTS_WINDOWS_LANGUAGE_ID_SINHALA                             :: 91;
    KBTS_WINDOWS_LANGUAGE_ID_SINHALA_SRI_LANKA                   :: 1115;
    KBTS_WINDOWS_LANGUAGE_ID_SLOVAK                              :: 27;
    KBTS_WINDOWS_LANGUAGE_ID_SLOVAK_SLOVAKIA                     :: 1051;
    KBTS_WINDOWS_LANGUAGE_ID_SLOVENIAN                           :: 36;
    KBTS_WINDOWS_LANGUAGE_ID_SLOVENIAN_SLOVENIA                  :: 1060;
    KBTS_WINDOWS_LANGUAGE_ID_SOMALI                              :: 119;
    KBTS_WINDOWS_LANGUAGE_ID_SOMALI_SOMALIA                      :: 1143;
    KBTS_WINDOWS_LANGUAGE_ID_SOTHO                               :: 48;
    KBTS_WINDOWS_LANGUAGE_ID_SOTHO_SOUTH_AFRICA                  :: 1072;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH                             :: 10;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_ARGENTINA                   :: 11274;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_VENEZUELA                   :: 8202;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_BOLIVIA                     :: 16394;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_CHILE                       :: 13322;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_COLOMBIA                    :: 9226;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_COSTA_RICA                  :: 5130;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_CUBA                        :: 23562;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_DOMINICAN_REPUBLIC          :: 7178;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_ECUADOR                     :: 12298;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_EL_SALVADOR                 :: 17418;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_GUATEMALA                   :: 4106;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_HONDURAS                    :: 18442;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_LATIN_AMERICA               :: 22538;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_MEXICO                      :: 2058;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_NICARAGUA                   :: 19466;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_PANAMA                      :: 6154;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_PARAGUAY                    :: 15370;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_PERU                        :: 10250;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_PUERTO_RICO                 :: 20490;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_SPAIN_TRADITIONAL_SORT      :: 1034;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_SPAIN                       :: 3082;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_UNITED_STATES               :: 21514;
    KBTS_WINDOWS_LANGUAGE_ID_SPANISH_URUGUAY                     :: 14346;
    KBTS_WINDOWS_LANGUAGE_ID_SWEDISH                             :: 29;
    KBTS_WINDOWS_LANGUAGE_ID_SWEDISH_FINLAND                     :: 2077;
    KBTS_WINDOWS_LANGUAGE_ID_SWEDISH_SWEDEN                      :: 1053;
    KBTS_WINDOWS_LANGUAGE_ID_SYRIAC                              :: 90;
    KBTS_WINDOWS_LANGUAGE_ID_SYRIAC_SYRIA                        :: 1114;
    KBTS_WINDOWS_LANGUAGE_ID_TAJIKI                              :: 40;
    KBTS_WINDOWS_LANGUAGE_ID_TAJIKI_CYRILLIC                     :: 31784;
    KBTS_WINDOWS_LANGUAGE_ID_TAJIKI_CYRILLIC_TAJIKISTAN          :: 1064;
    KBTS_WINDOWS_LANGUAGE_ID_TAMAZIGHT                           :: 95;
    KBTS_WINDOWS_LANGUAGE_ID_TAMAZIGHT_LATIN                     :: 31839;
    KBTS_WINDOWS_LANGUAGE_ID_TAMAZIGHT_LATIN_ALGERIA             :: 2143;
    KBTS_WINDOWS_LANGUAGE_ID_TAMIL                               :: 73;
    KBTS_WINDOWS_LANGUAGE_ID_TAMIL_INDIA                         :: 1097;
    KBTS_WINDOWS_LANGUAGE_ID_TAMIL_SRI_LANKA                     :: 2121;
    KBTS_WINDOWS_LANGUAGE_ID_TATAR                               :: 68;
    KBTS_WINDOWS_LANGUAGE_ID_TATAR_RUSSIA                        :: 1092;
    KBTS_WINDOWS_LANGUAGE_ID_TELUGU                              :: 74;
    KBTS_WINDOWS_LANGUAGE_ID_TELUGU_INDIA                        :: 1098;
    KBTS_WINDOWS_LANGUAGE_ID_THAI                                :: 30;
    KBTS_WINDOWS_LANGUAGE_ID_THAI_THAILAND                       :: 1054;
    KBTS_WINDOWS_LANGUAGE_ID_TIBETAN                             :: 81;
    KBTS_WINDOWS_LANGUAGE_ID_TIBETAN_PRC                         :: 1105;
    KBTS_WINDOWS_LANGUAGE_ID_TIGRINYA                            :: 115;
    KBTS_WINDOWS_LANGUAGE_ID_TIGRINYA_ERITREA                    :: 2163;
    KBTS_WINDOWS_LANGUAGE_ID_TIGRINYA_ETHIOPIA                   :: 1139;
    KBTS_WINDOWS_LANGUAGE_ID_TSONGA                              :: 49;
    KBTS_WINDOWS_LANGUAGE_ID_TSONGA_SOUTH_AFRICA                 :: 1073;
    KBTS_WINDOWS_LANGUAGE_ID_TURKISH                             :: 31;
    KBTS_WINDOWS_LANGUAGE_ID_TURKISH_TURKEY                      :: 1055;
    KBTS_WINDOWS_LANGUAGE_ID_TURKMEN                             :: 66;
    KBTS_WINDOWS_LANGUAGE_ID_TURKMEN_TURKMENISTAN                :: 1090;
    KBTS_WINDOWS_LANGUAGE_ID_UKRAINIAN                           :: 34;
    KBTS_WINDOWS_LANGUAGE_ID_UKRAINIAN_UKRAINE                   :: 1058;
    KBTS_WINDOWS_LANGUAGE_ID_UPPER_SORBIAN                       :: 46;
    KBTS_WINDOWS_LANGUAGE_ID_UPPER_SORBIAN_GERMANY               :: 1070;
    KBTS_WINDOWS_LANGUAGE_ID_URDU                                :: 32;
    KBTS_WINDOWS_LANGUAGE_ID_URDU_INDIA                          :: 2080;
    KBTS_WINDOWS_LANGUAGE_ID_URDU_PAKISTAN                       :: 1056;
    KBTS_WINDOWS_LANGUAGE_ID_UYGHUR                              :: 128;
    KBTS_WINDOWS_LANGUAGE_ID_UYGHUR_PRC                          :: 1152;
    KBTS_WINDOWS_LANGUAGE_ID_UZBEK_CYRILLIC                      :: 30787;
    KBTS_WINDOWS_LANGUAGE_ID_UZBEK_CYRILLIC_UZBEKISTAN           :: 2115;
    KBTS_WINDOWS_LANGUAGE_ID_UZBEK                               :: 67;
    KBTS_WINDOWS_LANGUAGE_ID_UZBEK_LATIN                         :: 31811;
    KBTS_WINDOWS_LANGUAGE_ID_UZBEK_LATIN_UZBEKISTAN              :: 1091;
    KBTS_WINDOWS_LANGUAGE_ID_VALENCIAN_SPAIN                     :: 2051;
    KBTS_WINDOWS_LANGUAGE_ID_VENDA                               :: 51;
    KBTS_WINDOWS_LANGUAGE_ID_VENDA_SOUTH_AFRICA                  :: 1075;
    KBTS_WINDOWS_LANGUAGE_ID_VIETNAMESE                          :: 42;
    KBTS_WINDOWS_LANGUAGE_ID_VIETNAMESE_VIETNAM                  :: 1066;
    KBTS_WINDOWS_LANGUAGE_ID_WELSH                               :: 82;
    KBTS_WINDOWS_LANGUAGE_ID_WELSH_UNITED_KINGDOM                :: 1106;
    KBTS_WINDOWS_LANGUAGE_ID_WOLOF                               :: 136;
    KBTS_WINDOWS_LANGUAGE_ID_WOLOF_SENEGAL                       :: 1160;
    KBTS_WINDOWS_LANGUAGE_ID_XHOSA                               :: 52;
    KBTS_WINDOWS_LANGUAGE_ID_XHOSA_SOUTH_AFRICA                  :: 1076;
    KBTS_WINDOWS_LANGUAGE_ID_YI                                  :: 120;
    KBTS_WINDOWS_LANGUAGE_ID_YI_PRC                              :: 1144;
    KBTS_WINDOWS_LANGUAGE_ID_YIDDISH                             :: 1085;
    KBTS_WINDOWS_LANGUAGE_ID_YORUBA                              :: 106;
    KBTS_WINDOWS_LANGUAGE_ID_YORUBA_NIGERIA                      :: 1130;
    KBTS_WINDOWS_LANGUAGE_ID_ZULU                                :: 53;
    KBTS_WINDOWS_LANGUAGE_ID_ZULU_SOUTH_AFRICA                   :: 1077;
}

kbts_language :: u32;
kbts_language_enum :: enum u32 {
    KBTS_LANGUAGE_DONT_KNOW                     :: 0;

    KBTS_LANGUAGE_A_HMAO                        :: 541347144;
    KBTS_LANGUAGE_AARI                          :: 541676097;
    KBTS_LANGUAGE_ABAZA                         :: 541147713;
    KBTS_LANGUAGE_ABKHAZIAN                     :: 541803073;
    KBTS_LANGUAGE_ACHI                          :: 542262081;
    KBTS_LANGUAGE_ACHOLI                        :: 541606721;
    KBTS_LANGUAGE_ADYGHE                        :: 542721089;
    KBTS_LANGUAGE_AFAR                          :: 542262849;
    KBTS_LANGUAGE_AFRIKAANS                     :: 541804097;
    KBTS_LANGUAGE_AGAW                          :: 542590785;
    KBTS_LANGUAGE_AITON                         :: 542067009;
    KBTS_LANGUAGE_AKAN                          :: 541150017;
    KBTS_LANGUAGE_ALBANIAN                      :: 541675859;
    KBTS_LANGUAGE_ALSATIAN                      :: 542329921;
    KBTS_LANGUAGE_ALTAI                         :: 542395457;
    KBTS_LANGUAGE_ALUO                          :: 541150809;
    KBTS_LANGUAGE_AMERICAN_PHONETIC             :: 1213222977;
    KBTS_LANGUAGE_AMHARIC                       :: 541609281;
    KBTS_LANGUAGE_ANGLO_SAXON                   :: 541544001;
    KBTS_LANGUAGE_ARABIC                        :: 541151809;
    KBTS_LANGUAGE_ARAGONESE                     :: 541545025;
    KBTS_LANGUAGE_ARAKANESE                     :: 541807169;
    KBTS_LANGUAGE_ARAKWAL                       :: 542591826;
    KBTS_LANGUAGE_ARMENIAN                      :: 541415752;
    KBTS_LANGUAGE_ARMENIAN_EAST                 :: 809851208;
    KBTS_LANGUAGE_AROMANIAN                     :: 542135634;
    KBTS_LANGUAGE_ARPITAN                       :: 542134854;
    KBTS_LANGUAGE_ASSAMESE                      :: 541938497;
    KBTS_LANGUAGE_ASTURIAN                      :: 542397249;
    KBTS_LANGUAGE_ATHAPASKAN                    :: 541611073;
    KBTS_LANGUAGE_ATSINA                        :: 542331969;
    KBTS_LANGUAGE_AVAR                          :: 542266945;
    KBTS_LANGUAGE_AVATIME                       :: 542004801;
    KBTS_LANGUAGE_AWADHI                        :: 541153089;
    KBTS_LANGUAGE_AYMARA                        :: 541940033;
    KBTS_LANGUAGE_AZERBAIJANI                   :: 541416001;
    KBTS_LANGUAGE_BADAGA                        :: 541344066;
    KBTS_LANGUAGE_BAGHELKHANDI                  :: 541540674;
    KBTS_LANGUAGE_BAGRI                         :: 542197570;
    KBTS_LANGUAGE_BALANTE                       :: 542002242;
    KBTS_LANGUAGE_BALINESE                      :: 541999426;
    KBTS_LANGUAGE_BALKAR                        :: 541868354;
    KBTS_LANGUAGE_BALTI                         :: 542395458;
    KBTS_LANGUAGE_BALUCHI                       :: 541674562;
    KBTS_LANGUAGE_BAMBARA                       :: 541216066;
    KBTS_LANGUAGE_BAMILEKE                      :: 541871426;
    KBTS_LANGUAGE_BANDA                         :: 809779522;
    KBTS_LANGUAGE_BANDJALANG                    :: 542721090;
    KBTS_LANGUAGE_BANGLA                        :: 542000450;
    KBTS_LANGUAGE_BASHKIR                       :: 541610818;
    KBTS_LANGUAGE_BASQUE                        :: 542201157;
    KBTS_LANGUAGE_BATAK                         :: 541807682;
    KBTS_LANGUAGE_BATAK_ALAS_KLUET              :: 542790722;
    KBTS_LANGUAGE_BATAK_ANGKOLA                 :: 541215553;
    KBTS_LANGUAGE_BATAK_DAIRI                   :: 541348930;
    KBTS_LANGUAGE_BATAK_KARO                    :: 542659650;
    KBTS_LANGUAGE_BATAK_MANDAILING              :: 541938754;
    KBTS_LANGUAGE_BATAK_SIMALUNGUN              :: 542331970;
    KBTS_LANGUAGE_BATAK_TOBA                    :: 541278786;
    KBTS_LANGUAGE_BAULE                         :: 542458178;
    KBTS_LANGUAGE_BAVARIAN                      :: 542261570;
    KBTS_LANGUAGE_BELARUSIAN                    :: 541869378;
    KBTS_LANGUAGE_BEMBA                         :: 541934914;
    KBTS_LANGUAGE_BENCH                         :: 541606722;
    KBTS_LANGUAGE_BERBER                        :: 542261826;
    KBTS_LANGUAGE_BETI                          :: 541676610;
    KBTS_LANGUAGE_BETTE_KURUMA                  :: 541218136;
    KBTS_LANGUAGE_BHILI                         :: 541673538;
    KBTS_LANGUAGE_BHOJPURI                      :: 542066754;
    KBTS_LANGUAGE_BHUTANESE                     :: 542005828;
    KBTS_LANGUAGE_BIBLE_CREE                    :: 542262082;
    KBTS_LANGUAGE_BIKOL                         :: 541804866;
    KBTS_LANGUAGE_BILEN                         :: 541870402;
    KBTS_LANGUAGE_BISHNUPRIYA_MANIPURI          :: 542724162;
    KBTS_LANGUAGE_BISLAMA                       :: 542329154;
    KBTS_LANGUAGE_BLACKFOOT                     :: 541477698;
    KBTS_LANGUAGE_BODO                          :: 542659138;
    KBTS_LANGUAGE_BOSNIAN                       :: 542330690;
    KBTS_LANGUAGE_BOUYEI                        :: 541279056;
    KBTS_LANGUAGE_BRAHUI                        :: 541610562;
    KBTS_LANGUAGE_BRAJ_BHASHA                   :: 541676098;
    KBTS_LANGUAGE_BRETON                        :: 541413954;
    KBTS_LANGUAGE_BUGIS                         :: 541545794;
    KBTS_LANGUAGE_BULGARIAN                     :: 542263106;
    KBTS_LANGUAGE_BUMTHANGKHA                   :: 542788171;
    KBTS_LANGUAGE_BURMESE                       :: 541938242;
    KBTS_LANGUAGE_BURUSHASKI                    :: 541807426;
    KBTS_LANGUAGE_CAJUN_FRENCH                  :: 541282886;
    KBTS_LANGUAGE_CARRIER                       :: 542265923;
    KBTS_LANGUAGE_CATALAN                       :: 542392643;
    KBTS_LANGUAGE_CAYUGA                        :: 542720323;
    KBTS_LANGUAGE_CEBUANO                       :: 541214019;
    KBTS_LANGUAGE_CENTRAL_YUPIK                 :: 542462789;
    KBTS_LANGUAGE_CHAHA_GURAGE                  :: 541542467;
    KBTS_LANGUAGE_CHAMORRO                      :: 541149251;
    KBTS_LANGUAGE_CHATTISGARHI                  :: 541608003;
    KBTS_LANGUAGE_CHECHEN                       :: 541411395;
    KBTS_LANGUAGE_CHEROKEE                      :: 542263363;
    KBTS_LANGUAGE_CHEYENNE                      :: 542722115;
    KBTS_LANGUAGE_CHICHEWA                      :: 541673539;
    KBTS_LANGUAGE_CHIGA                         :: 541542211;
    KBTS_LANGUAGE_CHIMILA                       :: 541540931;
    KBTS_LANGUAGE_CHIN                          :: 542001489;
    KBTS_LANGUAGE_CHINANTEC                     :: 1313358659;
    KBTS_LANGUAGE_CHINESE_PHONETIC              :: 542132314;
    KBTS_LANGUAGE_CHINESE_SIMPLIFIED            :: 542328922;
    KBTS_LANGUAGE_CHINESE_TRADITIONAL           :: 542394458;
    KBTS_LANGUAGE_CHINESE_TRADITIONAL_HONG_KONG :: 541608026;
    KBTS_LANGUAGE_CHINESE_TRADITIONAL_MACAO     :: 1297369178;
    KBTS_LANGUAGE_CHIPEWYAN                     :: 542132291;
    KBTS_LANGUAGE_CHITTAGONIAN                  :: 541545539;
    KBTS_LANGUAGE_CHOCTAW                       :: 542066755;
    KBTS_LANGUAGE_CHUKCHI                       :: 541804611;
    KBTS_LANGUAGE_CHURCH_SLAVONIC               :: 541872963;
    KBTS_LANGUAGE_CHUUKESE                      :: 810240067;
    KBTS_LANGUAGE_CHUVASH                       :: 542459971;
    KBTS_LANGUAGE_COMORIAN                      :: 542264643;
    KBTS_LANGUAGE_COMOX                         :: 542068547;
    KBTS_LANGUAGE_COPTIC                        :: 542134083;
    KBTS_LANGUAGE_CORNISH                       :: 542265155;
    KBTS_LANGUAGE_CORSICAN                      :: 542330691;
    KBTS_LANGUAGE_CREE                          :: 541413955;
    KBTS_LANGUAGE_CREOLES                       :: 542134339;
    KBTS_LANGUAGE_CRIMEAN_TATAR                 :: 542396995;
    KBTS_LANGUAGE_CRIOULO                       :: 541148491;
    KBTS_LANGUAGE_CROATIAN                      :: 542528072;
    KBTS_LANGUAGE_CYPRIOT_ARABIC                :: 542720833;
    KBTS_LANGUAGE_CZECH                         :: 542724931;
    KBTS_LANGUAGE_DAGBANI                       :: 541540676;
    KBTS_LANGUAGE_DAN                           :: 541740612;
    KBTS_LANGUAGE_DANGME                        :: 541544004;
    KBTS_LANGUAGE_DANISH                        :: 541999428;
    KBTS_LANGUAGE_DARGWA                        :: 542261572;
    KBTS_LANGUAGE_DARI                          :: 541676100;
    KBTS_LANGUAGE_DAYI                          :: 542654788;
    KBTS_LANGUAGE_DEFAULT                       :: 1953261156;
    KBTS_LANGUAGE_DEHONG_DAI                    :: 541344852;
    KBTS_LANGUAGE_DHANGU                        :: 541542468;
    KBTS_LANGUAGE_DHIVEHI                       :: 542525764;
    KBTS_LANGUAGE_DHUWAL                        :: 541742404;
    KBTS_LANGUAGE_DIMLI                         :: 542198084;
    KBTS_LANGUAGE_DINKA                         :: 541806148;
    KBTS_LANGUAGE_DIVEHI                        :: 542525764;
    KBTS_LANGUAGE_DJAMBARRPUYNGU                :: 810699332;
    KBTS_LANGUAGE_DOGRI                         :: 542066500;
    KBTS_LANGUAGE_DOGRI_MACROLANGUAGE           :: 542263108;
    KBTS_LANGUAGE_DUNGAN                        :: 542004548;
    KBTS_LANGUAGE_DUTCH                         :: 541346894;
    KBTS_LANGUAGE_DZONGKHA                      :: 542005828;
    KBTS_LANGUAGE_EASTERN_ABENAKI               :: 542196033;
    KBTS_LANGUAGE_EASTERN_CHAM                  :: 541936195;
    KBTS_LANGUAGE_EASTERN_CREE                  :: 542262085;
    KBTS_LANGUAGE_EASTERN_MANINKAKAN            :: 541805893;
    KBTS_LANGUAGE_EASTERN_PWO_KAREN             :: 542132811;
    KBTS_LANGUAGE_EBIRA                         :: 541672005;
    KBTS_LANGUAGE_EDO                           :: 542065733;
    KBTS_LANGUAGE_EFIK                          :: 541673029;
    KBTS_LANGUAGE_EMBERA_BAUDO                  :: 541279298;
    KBTS_LANGUAGE_EMBERA_CATIO                  :: 542069827;
    KBTS_LANGUAGE_EMBERA_CHAMI                  :: 541674819;
    KBTS_LANGUAGE_EMBERA_TADO                   :: 541279316;
    KBTS_LANGUAGE_ENGLISH                       :: 541544005;
    KBTS_LANGUAGE_EPENA                         :: 541149779;
    KBTS_LANGUAGE_ERZYA                         :: 542790213;
    KBTS_LANGUAGE_ESPERANTO                     :: 542069838;
    KBTS_LANGUAGE_ESTONIAN                      :: 541676613;
    KBTS_LANGUAGE_EVEN                          :: 542004805;
    KBTS_LANGUAGE_EVENKI                        :: 541808197;
    KBTS_LANGUAGE_EWE                           :: 541415237;
    KBTS_LANGUAGE_FALAM_CHIN                    :: 541868360;
    KBTS_LANGUAGE_FANG                          :: 810434886;
    KBTS_LANGUAGE_FANTI                         :: 542392646;
    KBTS_LANGUAGE_FAROESE                       :: 542330694;
    KBTS_LANGUAGE_FEFE                          :: 542133574;
    KBTS_LANGUAGE_FIJIAN                        :: 541674054;
    KBTS_LANGUAGE_FILIPINO                      :: 541870416;
    KBTS_LANGUAGE_FINNISH                       :: 542001478;
    KBTS_LANGUAGE_FLEMISH                       :: 541412422;
    KBTS_LANGUAGE_FON                           :: 542003014;
    KBTS_LANGUAGE_FOREST_ENETS                  :: 541412934;
    KBTS_LANGUAGE_FRENCH                        :: 541151814;
    KBTS_LANGUAGE_FRENCH_ANTILLEAN              :: 541999430;
    KBTS_LANGUAGE_FRISIAN                       :: 541676102;
    KBTS_LANGUAGE_FRIULIAN                      :: 541872710;
    KBTS_LANGUAGE_FULAH                         :: 541873478;
    KBTS_LANGUAGE_FUTA                          :: 541152326;
    KBTS_LANGUAGE_GA                            :: 541344071;
    KBTS_LANGUAGE_GAGAUZ                        :: 541540679;
    KBTS_LANGUAGE_GALICIAN                      :: 541868359;
    KBTS_LANGUAGE_GANDA                         :: 541545804;
    KBTS_LANGUAGE_GARHWALI                      :: 542589255;
    KBTS_LANGUAGE_GARO                          :: 542069319;
    KBTS_LANGUAGE_GARSHUNI                      :: 542261575;
    KBTS_LANGUAGE_GEBA_KAREN                    :: 542201419;
    KBTS_LANGUAGE_GEEZ                          :: 542786887;
    KBTS_LANGUAGE_GEORGIAN                      :: 542392651;
    KBTS_LANGUAGE_GEPO                          :: 542132057;
    KBTS_LANGUAGE_GERMAN                        :: 542459204;
    KBTS_LANGUAGE_GIKUYU                        :: 541804875;
    KBTS_LANGUAGE_GILAKI                        :: 541805639;
    KBTS_LANGUAGE_GILBERTESE                    :: 810305863;
    KBTS_LANGUAGE_GILYAK                        :: 541870407;
    KBTS_LANGUAGE_GITHABUL                      :: 541608263;
    KBTS_LANGUAGE_GOGO                          :: 541544263;
    KBTS_LANGUAGE_GONDI                         :: 542003015;
    KBTS_LANGUAGE_GREEK                         :: 541871173;
    KBTS_LANGUAGE_GREENLANDIC                   :: 542003783;
    KBTS_LANGUAGE_GUARANI                       :: 541152583;
    KBTS_LANGUAGE_GUINEA                        :: 542133063;
    KBTS_LANGUAGE_GUJARATI                      :: 541742407;
    KBTS_LANGUAGE_GUMATJ                        :: 542002759;
    KBTS_LANGUAGE_GUMUZ                         :: 542788935;
    KBTS_LANGUAGE_GUPAPUYNGU                    :: 541480263;
    KBTS_LANGUAGE_GUSII                         :: 542790983;
    KBTS_LANGUAGE_HAIDA                         :: 810107208;
    KBTS_LANGUAGE_HAITIAN_CREOLE                :: 541671752;
    KBTS_LANGUAGE_HALKOMELEM                    :: 542266696;
    KBTS_LANGUAGE_HAMMER_BANNA                  :: 541999688;
    KBTS_LANGUAGE_HARARI                        :: 541676104;
    KBTS_LANGUAGE_HARAUTI                       :: 542261576;
    KBTS_LANGUAGE_HARYANVI                      :: 541280066;
    KBTS_LANGUAGE_HAUSA                         :: 542458184;
    KBTS_LANGUAGE_HAVASUPAI_WALAPAI_YAVAPAI     :: 541480281;
    KBTS_LANGUAGE_HAWAIIAN                      :: 542589256;
    KBTS_LANGUAGE_HAYA                          :: 542720328;
    KBTS_LANGUAGE_HAZARAGI                      :: 542785864;
    KBTS_LANGUAGE_HEBREW                        :: 542267209;
    KBTS_LANGUAGE_HEILTSUK                      :: 541672776;
    KBTS_LANGUAGE_HERERO                        :: 542262600;
    KBTS_LANGUAGE_HIGH_MARI                     :: 541150536;
    KBTS_LANGUAGE_HILIGAYNON                    :: 541870408;
    KBTS_LANGUAGE_HINDI                         :: 542001480;
    KBTS_LANGUAGE_HINDKO                        :: 541347400;
    KBTS_LANGUAGE_HIRI_MOTU                     :: 542068040;
    KBTS_LANGUAGE_HMONG                         :: 542002504;
    KBTS_LANGUAGE_HMONG_DAW                     :: 542594893;
    KBTS_LANGUAGE_HMONG_SHUAT                   :: 542788936;
    KBTS_LANGUAGE_HO                            :: 538988360;
    KBTS_LANGUAGE_HUNGARIAN                     :: 542004552;
    KBTS_LANGUAGE_IBAN                          :: 541147721;
    KBTS_LANGUAGE_IBIBIO                        :: 541213257;
    KBTS_LANGUAGE_ICELANDIC                     :: 541872969;
    KBTS_LANGUAGE_IDO                           :: 542065737;
    KBTS_LANGUAGE_IGBO                          :: 542065225;
    KBTS_LANGUAGE_IJO                           :: 542067273;
    KBTS_LANGUAGE_ILOKANO                       :: 542067785;
    KBTS_LANGUAGE_INARI_SAMI                    :: 541938505;
    KBTS_LANGUAGE_INDONESIAN                    :: 541347401;
    KBTS_LANGUAGE_INGUSH                        :: 541544009;
    KBTS_LANGUAGE_INTERLINGUA                   :: 541150793;
    KBTS_LANGUAGE_INTERLINGUE                   :: 541412425;
    KBTS_LANGUAGE_INUKTITUT                     :: 542461513;
    KBTS_LANGUAGE_INUPIAT                       :: 541806665;
    KBTS_LANGUAGE_IPA_PHONETIC                  :: 542134345;
    KBTS_LANGUAGE_IRISH                         :: 541676105;
    KBTS_LANGUAGE_IRISH_TRADITIONAL             :: 542397001;
    KBTS_LANGUAGE_IRULA                         :: 542462537;
    KBTS_LANGUAGE_ITALIAN                       :: 541152329;
    KBTS_LANGUAGE_JAMAICAN_CREOLE               :: 541933898;
    KBTS_LANGUAGE_JAPANESE                      :: 541999434;
    KBTS_LANGUAGE_JAVANESE                      :: 542523722;
    KBTS_LANGUAGE_JENNU_KURUMA                  :: 541742424;
    KBTS_LANGUAGE_JUDEO_TAT                     :: 542393418;
    KBTS_LANGUAGE_JULA                          :: 541873482;
    KBTS_LANGUAGE_KABARDIAN                     :: 541213003;
    KBTS_LANGUAGE_KABYLE                        :: 809648459;
    KBTS_LANGUAGE_KACHCHI                       :: 541278539;
    KBTS_LANGUAGE_KADIWEU                       :: 541278795;
    KBTS_LANGUAGE_KALENJIN                      :: 541868363;
    KBTS_LANGUAGE_KALMYK                        :: 541936715;
    KBTS_LANGUAGE_KAMBA                         :: 541216075;
    KBTS_LANGUAGE_KANAUJI                       :: 541739586;
    KBTS_LANGUAGE_KANNADA                       :: 541999435;
    KBTS_LANGUAGE_KANURI                        :: 542264907;
    KBTS_LANGUAGE_KAQCHIKEL                     :: 541802819;
    KBTS_LANGUAGE_KARACHAY                      :: 542261579;
    KBTS_LANGUAGE_KARAIM                        :: 541938251;
    KBTS_LANGUAGE_KARAKALPAK                    :: 541807179;
    KBTS_LANGUAGE_KARELIAN                      :: 541872715;
    KBTS_LANGUAGE_KAREN                         :: 542003787;
    KBTS_LANGUAGE_KASHMIRI                      :: 541610827;
    KBTS_LANGUAGE_KASHUBIAN                     :: 541217603;
    KBTS_LANGUAGE_KATE                          :: 541543755;
    KBTS_LANGUAGE_KAZAKH                        :: 542785867;
    KBTS_LANGUAGE_KEBENA                        :: 541214027;
    KBTS_LANGUAGE_KEKCHI                        :: 541803851;
    KBTS_LANGUAGE_KHAKASS                       :: 541149259;
    KBTS_LANGUAGE_KHAMTI_SHAN                   :: 542394443;
    KBTS_LANGUAGE_KHAMYANG                      :: 542462795;
    KBTS_LANGUAGE_KHANTY_KAZIM                  :: 541804619;
    KBTS_LANGUAGE_KHANTY_SHURISHKAR             :: 542328907;
    KBTS_LANGUAGE_KHANTY_VAKHI                  :: 542525515;
    KBTS_LANGUAGE_KHASI                         :: 541676363;
    KBTS_LANGUAGE_KHENGKHA                      :: 541477720;
    KBTS_LANGUAGE_KHINALUG                      :: 541739595;
    KBTS_LANGUAGE_KHMER                         :: 541935691;
    KBTS_LANGUAGE_KHORASANI_TURKIC              :: 542788939;
    KBTS_LANGUAGE_KHOWAR                        :: 542591051;
    KBTS_LANGUAGE_KHUTSURI_GEORGIAN             :: 541411147;
    KBTS_LANGUAGE_KICHE                         :: 541283665;
    KBTS_LANGUAGE_KIKONGO                       :: 542003019;
    KBTS_LANGUAGE_KILDIN_SAMI                   :: 541938507;
    KBTS_LANGUAGE_KINYARWANDA                   :: 541152594;
    KBTS_LANGUAGE_KIRMANJKI                     :: 542460235;
    KBTS_LANGUAGE_KISII                         :: 542329163;
    KBTS_LANGUAGE_KITUBA                        :: 542591821;
    KBTS_LANGUAGE_KODAGU                        :: 541347659;
    KBTS_LANGUAGE_KOKNI                         :: 542001995;
    KBTS_LANGUAGE_KOMI                          :: 541937483;
    KBTS_LANGUAGE_KOMI_PERMYAK                  :: 542134091;
    KBTS_LANGUAGE_KOMI_ZYRIAN                   :: 542789451;
    KBTS_LANGUAGE_KOMO                          :: 542068043;
    KBTS_LANGUAGE_KOMSO                         :: 542330187;
    KBTS_LANGUAGE_KONGO                         :: 810438475;
    KBTS_LANGUAGE_KONKANI                       :: 541806411;
    KBTS_LANGUAGE_KOORETE                       :: 542397003;
    KBTS_LANGUAGE_KOREAN                        :: 542265163;
    KBTS_LANGUAGE_KOREAN_OLD_HANGUL             :: 541609803;
    KBTS_LANGUAGE_KORYAK                        :: 541808971;
    KBTS_LANGUAGE_KOSRAEAN                      :: 542330699;
    KBTS_LANGUAGE_KPELLE                        :: 541872203;
    KBTS_LANGUAGE_KPELLE_LIBERIA                :: 541413464;
    KBTS_LANGUAGE_KRIO                          :: 541676107;
    KBTS_LANGUAGE_KRYMCHAK                      :: 542393162;
    KBTS_LANGUAGE_KUANYAMA                      :: 541152587;
    KBTS_LANGUAGE_KUBE                          :: 541476683;
    KBTS_LANGUAGE_KUI                           :: 541676875;
    KBTS_LANGUAGE_KULVI                         :: 541807947;
    KBTS_LANGUAGE_KUMAONI                       :: 542002507;
    KBTS_LANGUAGE_KUMYK                         :: 541939019;
    KBTS_LANGUAGE_KURDISH                       :: 542266699;
    KBTS_LANGUAGE_KURUKH                        :: 542463307;
    KBTS_LANGUAGE_KUY                           :: 542725451;
    KBTS_LANGUAGE_KWAKWALA                      :: 541808459;
    KBTS_LANGUAGE_KYRGYZ                        :: 542263627;
    KBTS_LANGUAGE_L_CREE                        :: 542262092;
    KBTS_LANGUAGE_LADAKHI                       :: 541803596;
    KBTS_LANGUAGE_LADIN                         :: 541344076;
    KBTS_LANGUAGE_LADINO                        :: 541349194;
    KBTS_LANGUAGE_LAHULI                        :: 541606220;
    KBTS_LANGUAGE_LAK                           :: 541802828;
    KBTS_LANGUAGE_LAKI                          :: 541674316;
    KBTS_LANGUAGE_LAMBANI                       :: 541933900;
    KBTS_LANGUAGE_LAMPUNG                       :: 542132812;
    KBTS_LANGUAGE_LAO                           :: 542064972;
    KBTS_LANGUAGE_LATIN                         :: 542392652;
    KBTS_LANGUAGE_LATVIAN                       :: 541677132;
    KBTS_LANGUAGE_LAZ                           :: 542785868;
    KBTS_LANGUAGE_LELEMI                        :: 541476172;
    KBTS_LANGUAGE_LEZGI                         :: 542786892;
    KBTS_LANGUAGE_LIGURIAN                      :: 541739340;
    KBTS_LANGUAGE_LIMBU                         :: 541216076;
    KBTS_LANGUAGE_LIMBURGISH                    :: 541935948;
    KBTS_LANGUAGE_LINGALA                       :: 542001484;
    KBTS_LANGUAGE_LIPO                          :: 542068812;
    KBTS_LANGUAGE_LISU                          :: 542329164;
    KBTS_LANGUAGE_LITHUANIAN                    :: 541611084;
    KBTS_LANGUAGE_LIV                           :: 542525772;
    KBTS_LANGUAGE_LOJBAN                        :: 542065226;
    KBTS_LANGUAGE_LOMA                          :: 541937484;
    KBTS_LANGUAGE_LOMBARD                       :: 542068044;
    KBTS_LANGUAGE_LOMWE                         :: 542592332;
    KBTS_LANGUAGE_LOW_MARI                      :: 541150540;
    KBTS_LANGUAGE_LOW_SAXON                     :: 542327886;
    KBTS_LANGUAGE_LOWER_SORBIAN                 :: 541217612;
    KBTS_LANGUAGE_LU                            :: 541344344;
    KBTS_LANGUAGE_LUBA_KATANGA                  :: 541218124;
    KBTS_LANGUAGE_LUBA_LULUA                    :: 541152588;
    KBTS_LANGUAGE_LULE_SAMI                     :: 541938508;
    KBTS_LANGUAGE_LUO                           :: 542070092;
    KBTS_LANGUAGE_LURI                          :: 541282892;
    KBTS_LANGUAGE_LUSHOOTSEED                   :: 542397772;
    KBTS_LANGUAGE_LUXEMBOURGISH                 :: 542790732;
    KBTS_LANGUAGE_LUYIA                         :: 541611340;
    KBTS_LANGUAGE_MACEDONIAN                    :: 541346637;
    KBTS_LANGUAGE_MADURA                        :: 541344077;
    KBTS_LANGUAGE_MAGAHI                        :: 541540685;
    KBTS_LANGUAGE_MAITHILI                      :: 541611085;
    KBTS_LANGUAGE_MAJANG                        :: 541737293;
    KBTS_LANGUAGE_MAKASAR                       :: 542264141;
    KBTS_LANGUAGE_MAKHUWA                       :: 541802829;
    KBTS_LANGUAGE_MAKONDE                       :: 541410379;
    KBTS_LANGUAGE_MALAGASY                      :: 541543501;
    KBTS_LANGUAGE_MALAY                         :: 542723149;
    KBTS_LANGUAGE_MALAYALAM                     :: 541868365;
    KBTS_LANGUAGE_MALAYALAM_REFORMED            :: 542264397;
    KBTS_LANGUAGE_MALE                          :: 541412429;
    KBTS_LANGUAGE_MALINKE                       :: 542002253;
    KBTS_LANGUAGE_MALTESE                       :: 542331981;
    KBTS_LANGUAGE_MAM                           :: 541933901;
    KBTS_LANGUAGE_MANCHU                        :: 541606733;
    KBTS_LANGUAGE_MANDAR                        :: 542262349;
    KBTS_LANGUAGE_MANDINKA                      :: 541347405;
    KBTS_LANGUAGE_MANINKA                       :: 541806157;
    KBTS_LANGUAGE_MANIPURI                      :: 541675085;
    KBTS_LANGUAGE_MANO                          :: 542524749;
    KBTS_LANGUAGE_MANSI                         :: 541999437;
    KBTS_LANGUAGE_MANX                          :: 542658125;
    KBTS_LANGUAGE_MAORI                         :: 541676109;
    KBTS_LANGUAGE_MAPUDUNGUN                    :: 542130509;
    KBTS_LANGUAGE_MARATHI                       :: 542261581;
    KBTS_LANGUAGE_MARSHALLESE                   :: 541606221;
    KBTS_LANGUAGE_MARWARI                       :: 542589261;
    KBTS_LANGUAGE_MAYAN                         :: 542005581;
    KBTS_LANGUAGE_MAZANDERANI                   :: 542005837;
    KBTS_LANGUAGE_MBEMBE_TIGON                  :: 541153870;
    KBTS_LANGUAGE_MBO                           :: 542065229;
    KBTS_LANGUAGE_MBUNDU                        :: 541999693;
    KBTS_LANGUAGE_MEDUMBA                       :: 542529858;
    KBTS_LANGUAGE_MEEN                          :: 542000461;
    KBTS_LANGUAGE_MENDE                         :: 541410381;
    KBTS_LANGUAGE_MERU                          :: 542262605;
    KBTS_LANGUAGE_MEWATI                        :: 541938775;
    KBTS_LANGUAGE_MINANGKABAU                   :: 542001485;
    KBTS_LANGUAGE_MINJANGBAL                    :: 541215320;
    KBTS_LANGUAGE_MIRANDESE                     :: 541873997;
    KBTS_LANGUAGE_MIZO                          :: 542787917;
    KBTS_LANGUAGE_MOHAWK                        :: 541609805;
    KBTS_LANGUAGE_MOKSHA                        :: 541806413;
    KBTS_LANGUAGE_MOLDAVIAN                     :: 541871949;
    KBTS_LANGUAGE_MON                           :: 542003021;
    KBTS_LANGUAGE_MONGOLIAN                     :: 541544013;
    KBTS_LANGUAGE_MOOSE_CREE                    :: 542262093;
    KBTS_LANGUAGE_MORISYEN                      :: 541410893;
    KBTS_LANGUAGE_MOROCCAN                      :: 542265165;
    KBTS_LANGUAGE_MOSSI                         :: 542330957;
    KBTS_LANGUAGE_MUNDARI                       :: 542004557;
    KBTS_LANGUAGE_MUSCOGEE                      :: 542332237;
    KBTS_LANGUAGE_N_CREE                        :: 542262094;
    KBTS_LANGUAGE_NAGA_ASSAMESE                 :: 541540686;
    KBTS_LANGUAGE_NAGARI                        :: 542263118;
    KBTS_LANGUAGE_NAHUATL                       :: 541606222;
    KBTS_LANGUAGE_NANAI                         :: 541999438;
    KBTS_LANGUAGE_NASKAPI                       :: 542327118;
    KBTS_LANGUAGE_NAURUAN                       :: 542458190;
    KBTS_LANGUAGE_NAVAJO                        :: 542523726;
    KBTS_LANGUAGE_NDAU                          :: 541279310;
    KBTS_LANGUAGE_NDEBELE                       :: 541213774;
    KBTS_LANGUAGE_NDONGA                        :: 541541454;
    KBTS_LANGUAGE_NEAPOLITAN                    :: 542130510;
    KBTS_LANGUAGE_NEPALI                        :: 542131534;
    KBTS_LANGUAGE_NEWARI                        :: 542590286;
    KBTS_LANGUAGE_NGBAKA                        :: 541149006;
    KBTS_LANGUAGE_NIGERIAN_FULFULDE             :: 542528838;
    KBTS_LANGUAGE_NIMADI                        :: 541413198;
    KBTS_LANGUAGE_NISI                          :: 542329166;
    KBTS_LANGUAGE_NIUEAN                        :: 542460238;
    KBTS_LANGUAGE_NKO                           :: 542067534;
    KBTS_LANGUAGE_NOGAI                         :: 541544270;
    KBTS_LANGUAGE_NORFOLK                       :: 541608272;
    KBTS_LANGUAGE_NORTH_SLAVEY                  :: 542327635;
    KBTS_LANGUAGE_NORTHERN_EMBERA               :: 542133573;
    KBTS_LANGUAGE_NORTHERN_SAMI                 :: 541938510;
    KBTS_LANGUAGE_NORTHERN_SOTHO                :: 542069582;
    KBTS_LANGUAGE_NORTHERN_TAI                  :: 541152334;
    KBTS_LANGUAGE_NORWAY_HOUSE_CREE             :: 541280334;
    KBTS_LANGUAGE_NORWEGIAN                     :: 542265166;
    KBTS_LANGUAGE_NORWEGIAN_NYNORSK             :: 542005582;
    KBTS_LANGUAGE_NOVIAL                        :: 542527310;
    KBTS_LANGUAGE_NUMANGGANG                    :: 542134094;
    KBTS_LANGUAGE_NUNAVIK_INUKTITUT             :: 542461513;
    KBTS_LANGUAGE_NUU_CHAH_NULTH                :: 541807950;
    KBTS_LANGUAGE_NYAMWEZI                      :: 541940046;
    KBTS_LANGUAGE_NYANKOLE                      :: 541870926;
    KBTS_LANGUAGE_OCCITAN                       :: 541672271;
    KBTS_LANGUAGE_ODIA                          :: 541676111;
    KBTS_LANGUAGE_OJI_CREE                      :: 542262095;
    KBTS_LANGUAGE_OJIBWAY                       :: 541215311;
    KBTS_LANGUAGE_OLD_IRISH                     :: 541149011;
    KBTS_LANGUAGE_OLD_JAVANESE                  :: 542589259;
    KBTS_LANGUAGE_ONEIDA                        :: 541412943;
    KBTS_LANGUAGE_ONONDAGA                      :: 542068303;
    KBTS_LANGUAGE_OROMO                         :: 542069327;
    KBTS_LANGUAGE_OSSETIAN                      :: 542331727;
    KBTS_LANGUAGE_PA_O_KAREN                    :: 541805634;
    KBTS_LANGUAGE_PALAUAN                       :: 542458192;
    KBTS_LANGUAGE_PALAUNG                       :: 541543504;
    KBTS_LANGUAGE_PALESTINIAN_ARAMAIC           :: 541147472;
    KBTS_LANGUAGE_PALI                          :: 541868368;
    KBTS_LANGUAGE_PALPA                         :: 542130512;
    KBTS_LANGUAGE_PAMPANGAN                     :: 541933904;
    KBTS_LANGUAGE_PANGASINAN                    :: 541540688;
    KBTS_LANGUAGE_PAPIAMENTU                    :: 810565968;
    KBTS_LANGUAGE_PASHTO                        :: 542327120;
    KBTS_LANGUAGE_PATTANI_MALAY                 :: 541148749;
    KBTS_LANGUAGE_PENNSYLVANIA_GERMAN           :: 541279312;
    KBTS_LANGUAGE_PERSIAN                       :: 542261574;
    KBTS_LANGUAGE_PHAKE                         :: 541805136;
    KBTS_LANGUAGE_PICARD                        :: 541344592;
    KBTS_LANGUAGE_PIEMONTESE                    :: 542330192;
    KBTS_LANGUAGE_PILAGA                        :: 541543504;
    KBTS_LANGUAGE_PITE_SAMI                     :: 541411923;
    KBTS_LANGUAGE_POCOMCHI                      :: 541609808;
    KBTS_LANGUAGE_POHNPEIAN                     :: 542003024;
    KBTS_LANGUAGE_POLISH                        :: 541805648;
    KBTS_LANGUAGE_POLYTONIC_GREEK               :: 542263120;
    KBTS_LANGUAGE_PORTUGUESE                    :: 541545552;
    KBTS_LANGUAGE_PROVENCAL                     :: 542069328;
    KBTS_LANGUAGE_PUNJABI                       :: 541999440;
    KBTS_LANGUAGE_QUECHUA                       :: 542790993;
    KBTS_LANGUAGE_QUECHUA_BOLIVIA               :: 541611345;
    KBTS_LANGUAGE_QUECHUA_ECUADOR               :: 541677137;
    KBTS_LANGUAGE_QUECHUA_PERU                  :: 541611857;
    KBTS_LANGUAGE_R_CREE                        :: 542262098;
    KBTS_LANGUAGE_RAJASTHANI                    :: 541737298;
    KBTS_LANGUAGE_RAKHINE                       :: 541807169;
    KBTS_LANGUAGE_RAROTONGAN                    :: 542261586;
    KBTS_LANGUAGE_REJANG                        :: 541738322;
    KBTS_LANGUAGE_RIANG                         :: 541149522;
    KBTS_LANGUAGE_RIPUARIAN                     :: 541610827;
    KBTS_LANGUAGE_RITARUNGO                     :: 542394706;
    KBTS_LANGUAGE_ROHINGYA                      :: 541542482;
    KBTS_LANGUAGE_ROMANIAN                      :: 541937490;
    KBTS_LANGUAGE_ROMANSH                       :: 542330194;
    KBTS_LANGUAGE_ROMANY                        :: 542723922;
    KBTS_LANGUAGE_ROTUMAN                       :: 541938770;
    KBTS_LANGUAGE_RUNDI                         :: 542004562;
    KBTS_LANGUAGE_RUSSIAN                       :: 542332242;
    KBTS_LANGUAGE_RUSSIAN_BURIAT                :: 542458450;
    KBTS_LANGUAGE_RUSYN                         :: 542724946;
    KBTS_LANGUAGE_SADRI                         :: 541344083;
    KBTS_LANGUAGE_SAKHA                         :: 541802841;
    KBTS_LANGUAGE_SAMOAN                        :: 542068051;
    KBTS_LANGUAGE_SAMOGITIAN                    :: 542328659;
    KBTS_LANGUAGE_SAN_BLAS_KUNA                 :: 541807939;
    KBTS_LANGUAGE_SANGO                         :: 542066515;
    KBTS_LANGUAGE_SANSKRIT                      :: 541999443;
    KBTS_LANGUAGE_SANTALI                       :: 542392659;
    KBTS_LANGUAGE_SARAIKI                       :: 541807187;
    KBTS_LANGUAGE_SARDINIAN                     :: 541348435;
    KBTS_LANGUAGE_SASAK                         :: 542327123;
    KBTS_LANGUAGE_SATERLAND_FRISIAN             :: 542200915;
    KBTS_LANGUAGE_SAYISI                        :: 542720339;
    KBTS_LANGUAGE_SCOTS                         :: 541672275;
    KBTS_LANGUAGE_SCOTTISH_GAELIC               :: 541409607;
    KBTS_LANGUAGE_SEKOTA                        :: 541738323;
    KBTS_LANGUAGE_SELKUP                        :: 541869395;
    KBTS_LANGUAGE_SENA                          :: 541150803;
    KBTS_LANGUAGE_SENECA                        :: 541410643;
    KBTS_LANGUAGE_SERBIAN                       :: 541217363;
    KBTS_LANGUAGE_SERER                         :: 542265939;
    KBTS_LANGUAGE_SGAW_KAREN                    :: 542593867;
    KBTS_LANGUAGE_SHAN                          :: 542001235;
    KBTS_LANGUAGE_SHONA                         :: 541150803;
    KBTS_LANGUAGE_SIBE                          :: 541215059;
    KBTS_LANGUAGE_SICILIAN                      :: 541999955;
    KBTS_LANGUAGE_SIDAMO                        :: 541346131;
    KBTS_LANGUAGE_SILESIAN                      :: 541874771;
    KBTS_LANGUAGE_SILTE_GURAGE                  :: 541542739;
    KBTS_LANGUAGE_SINDHI                        :: 541347411;
    KBTS_LANGUAGE_SINHALA                       :: 541609555;
    KBTS_LANGUAGE_SKOLT_SAMI                    :: 542329683;
    KBTS_LANGUAGE_SLAVEY                        :: 541150291;
    KBTS_LANGUAGE_SLOVAK                        :: 542722899;
    KBTS_LANGUAGE_SLOVENIAN                     :: 542526547;
    KBTS_LANGUAGE_SMALL_FLOWERY_MIAO            :: 541935187;
    KBTS_LANGUAGE_SODO_GURAGE                   :: 541544275;
    KBTS_LANGUAGE_SOGA                          :: 541544280;
    KBTS_LANGUAGE_SOMALI                        :: 541871443;
    KBTS_LANGUAGE_SONGE                         :: 542134099;
    KBTS_LANGUAGE_SONINKE                       :: 541806163;
    KBTS_LANGUAGE_SOUTH_SLAVEY                  :: 541872979;
    KBTS_LANGUAGE_SOUTHERN_KIWAI                :: 541346379;
    KBTS_LANGUAGE_SOUTHERN_SAMI                 :: 541938515;
    KBTS_LANGUAGE_SOUTHERN_SOTHO                :: 542396243;
    KBTS_LANGUAGE_SPANISH                       :: 542135109;
    KBTS_LANGUAGE_STANDARD_MOROCCAN_TAMAZIGHT   :: 541607770;
    KBTS_LANGUAGE_STRAITS_SALISH                :: 542266451;
    KBTS_LANGUAGE_SUKUMA                        :: 541807955;
    KBTS_LANGUAGE_SUNDANESE                     :: 542004563;
    KBTS_LANGUAGE_SURI                          :: 542266707;
    KBTS_LANGUAGE_SUTU                          :: 542398547;
    KBTS_LANGUAGE_SVAN                          :: 541152851;
    KBTS_LANGUAGE_SWADAYA_ARAMAIC               :: 541153107;
    KBTS_LANGUAGE_SWAHILI                       :: 541808467;
    KBTS_LANGUAGE_SWATI                         :: 542791507;
    KBTS_LANGUAGE_SWEDISH                       :: 541414995;
    KBTS_LANGUAGE_SYLHETI                       :: 541874515;
    KBTS_LANGUAGE_SYRIAC                        :: 542267731;
    KBTS_LANGUAGE_SYRIAC_EASTERN                :: 1314019667;
    KBTS_LANGUAGE_SYRIAC_ESTRANGELA             :: 1163024723;
    KBTS_LANGUAGE_SYRIAC_WESTERN                :: 1246910803;
    KBTS_LANGUAGE_TABASARAN                     :: 541213012;
    KBTS_LANGUAGE_TACHELHIT                     :: 541673555;
    KBTS_LANGUAGE_TAGALOG                       :: 541869908;
    KBTS_LANGUAGE_TAHAGGART_TAMAHAQ             :: 542525524;
    KBTS_LANGUAGE_TAHITIAN                      :: 542394452;
    KBTS_LANGUAGE_TAI_LAING                     :: 541870676;
    KBTS_LANGUAGE_TAJIKI                        :: 541737300;
    KBTS_LANGUAGE_TALYSH                        :: 542723156;
    KBTS_LANGUAGE_TAMASHEK                      :: 541609300;
    KBTS_LANGUAGE_TAMASHEQ                      :: 542196052;
    KBTS_LANGUAGE_TAMAZIGHT                     :: 541940308;
    KBTS_LANGUAGE_TAMIL                         :: 541933908;
    KBTS_LANGUAGE_TARIFIT                       :: 541477202;
    KBTS_LANGUAGE_TATAR                         :: 542392660;
    KBTS_LANGUAGE_TAWALLAMMAT_TAMAJAQ           :: 542200916;
    KBTS_LANGUAGE_TAY                           :: 542792020;
    KBTS_LANGUAGE_TAYART_TAMAJEQ                :: 542787668;
    KBTS_LANGUAGE_TELUGU                        :: 541869396;
    KBTS_LANGUAGE_TEMNE                         :: 542002516;
    KBTS_LANGUAGE_TETUM                         :: 542393684;
    KBTS_LANGUAGE_TH_CREE                       :: 542262100;
    KBTS_LANGUAGE_THAI                          :: 541149268;
    KBTS_LANGUAGE_THAILAND_MON                  :: 1414418253;
    KBTS_LANGUAGE_THOMPSON                      :: 542132308;
    KBTS_LANGUAGE_TIBETAN                       :: 541215060;
    KBTS_LANGUAGE_TIGRE                         :: 542263124;
    KBTS_LANGUAGE_TIGRINYA                      :: 542721876;
    KBTS_LANGUAGE_TIV                           :: 542525780;
    KBTS_LANGUAGE_TLINGIT                       :: 541674580;
    KBTS_LANGUAGE_TOBO                          :: 542523988;
    KBTS_LANGUAGE_TODO                          :: 541347668;
    KBTS_LANGUAGE_TOK_PISIN                     :: 541675604;
    KBTS_LANGUAGE_TOMA                          :: 809783124;
    KBTS_LANGUAGE_TONGA                         :: 541544020;
    KBTS_LANGUAGE_TONGAN                        :: 542000980;
    KBTS_LANGUAGE_TORKI                         :: 541219393;
    KBTS_LANGUAGE_TSHANGLA                      :: 541741908;
    KBTS_LANGUAGE_TSONGA                        :: 541545300;
    KBTS_LANGUAGE_TSWANA                        :: 541150804;
    KBTS_LANGUAGE_TULU                          :: 541873492;
    KBTS_LANGUAGE_TUMBUKA                       :: 541939028;
    KBTS_LANGUAGE_TUNDRA_ENETS                  :: 541412948;
    KBTS_LANGUAGE_TURKISH                       :: 541807188;
    KBTS_LANGUAGE_TURKMEN                       :: 541936468;
    KBTS_LANGUAGE_TUROYO_ARAMAIC                :: 541152596;
    KBTS_LANGUAGE_TUSCARORA                     :: 542332244;
    KBTS_LANGUAGE_TUVALU                        :: 541873748;
    KBTS_LANGUAGE_TUVIN                         :: 542528852;
    KBTS_LANGUAGE_TWI                           :: 541677396;
    KBTS_LANGUAGE_TZOTZIL                       :: 542071380;
    KBTS_LANGUAGE_UDI                           :: 541672533;
    KBTS_LANGUAGE_UDMURT                        :: 541934677;
    KBTS_LANGUAGE_UKRAINIAN                     :: 542264149;
    KBTS_LANGUAGE_UMBUNDU                       :: 541216085;
    KBTS_LANGUAGE_UME_SAMI                      :: 542460499;
    KBTS_LANGUAGE_UPPER_SAXON                   :: 542464083;
    KBTS_LANGUAGE_UPPER_SORBIAN                 :: 541217621;
    KBTS_LANGUAGE_URALIC_PHONETIC               :: 542134357;
    KBTS_LANGUAGE_URDU                          :: 541348437;
    KBTS_LANGUAGE_UYGHUR                        :: 541546837;
    KBTS_LANGUAGE_UZBEK                         :: 541219413;
    KBTS_LANGUAGE_VENDA                         :: 542000470;
    KBTS_LANGUAGE_VENETIAN                      :: 541279574;
    KBTS_LANGUAGE_VIETNAMESE                    :: 542394710;
    KBTS_LANGUAGE_VLAX_ROMANI                   :: 542723410;
    KBTS_LANGUAGE_VOLAPUK                       :: 541871958;
    KBTS_LANGUAGE_VORO                          :: 542069334;
    KBTS_LANGUAGE_WA                            :: 538984791;
    KBTS_LANGUAGE_WACI_GBE                      :: 541672279;
    KBTS_LANGUAGE_WAGDI                         :: 541540695;
    KBTS_LANGUAGE_WAKHI                         :: 541868631;
    KBTS_LANGUAGE_WALLOON                       :: 542002263;
    KBTS_LANGUAGE_WARAY_WARAY                   :: 542261591;
    KBTS_LANGUAGE_WAYANAD_CHETTI                :: 542397507;
    KBTS_LANGUAGE_WAYUU                         :: 541283655;
    KBTS_LANGUAGE_WELSH                         :: 541869399;
    KBTS_LANGUAGE_WENDAT                        :: 542393431;
    KBTS_LANGUAGE_WEST_CREE                     :: 542262103;
    KBTS_LANGUAGE_WESTERN_CHAM                  :: 541149763;
    KBTS_LANGUAGE_WESTERN_KAYAH                 :: 542464331;
    KBTS_LANGUAGE_WESTERN_PANJABI               :: 541216336;
    KBTS_LANGUAGE_WESTERN_PWO_KAREN             :: 542070608;
    KBTS_LANGUAGE_WOLOF                         :: 541477975;
    KBTS_LANGUAGE_WOODS_CREE                    :: 542262084;
    KBTS_LANGUAGE_WUDING_LUQUAN_YI              :: 542201689;
    KBTS_LANGUAGE_WYANDOT                       :: 542005591;
    KBTS_LANGUAGE_XHOSA                         :: 542328920;
    KBTS_LANGUAGE_Y_CREE                        :: 542262105;
    KBTS_LANGUAGE_YAO                           :: 542064985;
    KBTS_LANGUAGE_YAPESE                        :: 542130521;
    KBTS_LANGUAGE_YI_CLASSIC                    :: 541280601;
    KBTS_LANGUAGE_YI_MODERN                     :: 541935961;
    KBTS_LANGUAGE_YIDDISH                       :: 541673802;
    KBTS_LANGUAGE_YORUBA                        :: 541147737;
    KBTS_LANGUAGE_ZAMBOANGA_CHAVACANO           :: 541803075;
    KBTS_LANGUAGE_ZANDE                         :: 541347418;
    KBTS_LANGUAGE_ZARMA                         :: 542263876;
    KBTS_LANGUAGE_ZAZAKI                        :: 541153882;
    KBTS_LANGUAGE_ZEALANDIC                     :: 541148506;
    KBTS_LANGUAGE_ZHUANG                        :: 541149274;
    KBTS_LANGUAGE_ZULU                          :: 541873498;
}

kbts_break_flags :: u32;
kbts_break_flags_enum :: enum u32 {
    KBTS_BREAK_FLAG_DIRECTION           :: 1;

    KBTS_BREAK_FLAG_SCRIPT              :: 2;

    KBTS_BREAK_FLAG_GRAPHEME            :: 4;

    KBTS_BREAK_FLAG_WORD                :: 8;

    KBTS_BREAK_FLAG_LINE_SOFT           :: 16;

    KBTS_BREAK_FLAG_LINE_HARD           :: 32;

    KBTS_BREAK_FLAG_MANUAL              :: 64;

    KBTS_BREAK_FLAG_PARAGRAPH_DIRECTION :: 128;

    KBTS_BREAK_FLAG_LINE                :: 48;
    KBTS_BREAK_FLAG_ANY                 :: 63;
}

// Japanese text contains "kinsoku" characters, around which breaking a line is forbidden.
// Exactly which characters are "kinsoku" or not depends on the context:
// - Strict style has the largest amount of kinsoku characters, which leads to longer lines.
// - Loose style has the smallest amount of kinsoku characters, which leads to smaller lines.
// - Normal style is somewhere in the middle.
// Note that, while the Unicode standard mentions all three of these styles, it does not mention
// any differences between the normal and loose styles.
// As such, normal and loose styles currently behave the same.
kbts_japanese_line_break_style :: u8;
kbts_japanese_line_break_style_enum :: enum u32 {
    KBTS_JAPANESE_LINE_BREAK_STYLE_STRICT :: 0;

    KBTS_JAPANESE_LINE_BREAK_STYLE_NORMAL :: 1;

    KBTS_JAPANESE_LINE_BREAK_STYLE_LOOSE  :: 2;

    KBTS_JAPANESE_LINE_BREAK_STYLE_COUNT  :: 3;
}

kbts_break_state_flags :: u32;
kbts_break_state_flags_enum :: enum u32 {
    KBTS_BREAK_STATE_FLAG_STARTED          :: 1;
    KBTS_BREAK_STATE_FLAG_END              :: 2;

    KBTS_BREAK_STATE_FLAG_SAW_R_AFTER_L    :: 8;
    KBTS_BREAK_STATE_FLAG_SAW_AL_AFTER_LR  :: 16;
    KBTS_BREAK_STATE_FLAG_LAST_WAS_BRACKET :: 32;
}

kbts_shape_context_flags :: u32;
kbts_shape_context_flags_enum :: enum u32 {
    KBTS_SHAPE_CONTEXT_FLAG_NONE                        :: 0;

    KBTS_SHAPE_CONTEXT_FLAG_FONT_PRIORITY_BOTTOM_TO_TOP :: 1;
}

kbts_text_format :: u32;
kbts_text_format_enum :: enum u32 {
    KBTS_TEXT_FORMAT_NONE  :: 0;

    KBTS_TEXT_FORMAT_UTF32 :: 1;
    KBTS_TEXT_FORMAT_UTF8  :: 2;

    KBTS_TEXT_FORMAT_COUNT :: 3;
}

kbts_direction :: u32;
kbts_direction_enum :: enum u32 {
    KBTS_DIRECTION_DONT_KNOW :: 0;
    KBTS_DIRECTION_LTR       :: 1;
    KBTS_DIRECTION_RTL       :: 2;

    KBTS_DIRECTION_COUNT     :: 3;
}

kbts_orientation :: u32;
kbts_orientation_enum :: enum u32 {
    KBTS_ORIENTATION_HORIZONTAL :: 0;
    KBTS_ORIENTATION_VERTICAL   :: 1;

    KBTS_ORIENTATION_COUNT      :: 2;
}

kbts_shaping_table :: u8;
kbts_shaping_table_enum :: enum u32 {
    KBTS_SHAPING_TABLE_GSUB  :: 0;
    KBTS_SHAPING_TABLE_GPOS  :: 1;
    KBTS_SHAPING_TABLE_COUNT :: 2;
}

kbts_shape_error :: u32;
kbts_shape_error_enum :: enum u32 {
    KBTS_SHAPE_ERROR_NONE                           :: 0;
    KBTS_SHAPE_ERROR_INVALID_FONT                   :: 1;
    KBTS_SHAPE_ERROR_GAVE_TEXT_BEFORE_CALLING_BEGIN :: 2;
    KBTS_SHAPE_ERROR_OUT_OF_MEMORY                  :: 3;

    KBTS_SHAPE_ERROR_COUNT                          :: 4;
}

kbts_allocator_op_kind :: u32;
kbts_allocator_op_kind_enum :: enum u32 {
    KBTS_ALLOCATOR_OP_KIND_NONE     :: 0;
    KBTS_ALLOCATOR_OP_KIND_ALLOCATE :: 1;
    KBTS_ALLOCATOR_OP_KIND_FREE     :: 2;

    KBTS_ALLOCATOR_OP_KIND_COUNT    :: 3;
}

kbts_blob_table_id :: u32;
kbts_blob_table_id_enum :: enum u32 {
    KBTS_BLOB_TABLE_ID_NONE  :: 0;
    KBTS_BLOB_TABLE_ID_HEAD  :: 1;
    KBTS_BLOB_TABLE_ID_CMAP  :: 2;
    KBTS_BLOB_TABLE_ID_GDEF  :: 3;
    KBTS_BLOB_TABLE_ID_GSUB  :: 4;
    KBTS_BLOB_TABLE_ID_GPOS  :: 5;
    KBTS_BLOB_TABLE_ID_HHEA  :: 6;
    KBTS_BLOB_TABLE_ID_VHEA  :: 7;
    KBTS_BLOB_TABLE_ID_HMTX  :: 8;
    KBTS_BLOB_TABLE_ID_VMTX  :: 9;
    KBTS_BLOB_TABLE_ID_MAXP  :: 10;
    KBTS_BLOB_TABLE_ID_OS2   :: 11;
    KBTS_BLOB_TABLE_ID_NAME  :: 12;
    KBTS_BLOB_TABLE_ID_FVAR  :: 13;
    KBTS_BLOB_TABLE_ID_AVAR  :: 14;
    KBTS_BLOB_TABLE_ID_MVAR  :: 15;
    KBTS_BLOB_TABLE_ID_HVAR  :: 16;
    KBTS_BLOB_TABLE_ID_VVAR  :: 17;

    KBTS_BLOB_TABLE_ID_COUNT :: 18;
}

kbts_load_font_error :: u32;
kbts_load_font_error_enum :: enum u32 {
    KBTS_LOAD_FONT_ERROR_NONE                :: 0;
    KBTS_LOAD_FONT_ERROR_NEED_TO_CREATE_BLOB :: 1;
    KBTS_LOAD_FONT_ERROR_INVALID_FONT        :: 2;
    KBTS_LOAD_FONT_ERROR_OUT_OF_MEMORY       :: 3;
    KBTS_LOAD_FONT_ERROR_COULD_NOT_OPEN_FILE :: 4;
    KBTS_LOAD_FONT_ERROR_READ_ERROR          :: 5;

    KBTS_LOAD_FONT_ERROR_COUNT               :: 6;
}

kbts_version :: u32;
kbts_version_enum :: enum u32 {
    KBTS_VERSION_1_X     :: 0;
    KBTS_VERSION_2_0     :: 1;
    KBTS_VERSION_2_28    :: 2;

    KBTS_VERSION_CURRENT :: 2;
}

kbts_blob_version :: u32;
kbts_blob_version_enum :: enum u32 {
    KBTS_BLOB_VERSION_INVALID                               :: 0;
    KBTS_BLOB_VERSION_INITIAL                               :: 1;
    KBTS_BLOB_VERSION_REMOVED_SUBTABLE_INFOS_ALIGNED_TABLES :: 2;

    KBTS_BLOB_VERSION_CURRENT                               :: 2;
}

kbts_font_style_flags :: u32;
kbts_font_style_flags_enum :: enum u32 {
    KBTS_FONT_STYLE_FLAG_NONE    :: 0;

    KBTS_FONT_STYLE_FLAG_REGULAR :: 1;
    KBTS_FONT_STYLE_FLAG_ITALIC  :: 2;
    KBTS_FONT_STYLE_FLAG_BOLD    :: 4;
}

kbts_font_weight :: u32;
kbts_font_weight_enum :: enum u32 {
    KBTS_FONT_WEIGHT_UNKNOWN     :: 0;

    KBTS_FONT_WEIGHT_THIN        :: 1;
    KBTS_FONT_WEIGHT_EXTRA_LIGHT :: 2;
    KBTS_FONT_WEIGHT_LIGHT       :: 3;
    KBTS_FONT_WEIGHT_NORMAL      :: 4;
    KBTS_FONT_WEIGHT_MEDIUM      :: 5;
    KBTS_FONT_WEIGHT_SEMI_BOLD   :: 6;
    KBTS_FONT_WEIGHT_BOLD        :: 7;
    KBTS_FONT_WEIGHT_EXTRA_BOLD  :: 8;
    KBTS_FONT_WEIGHT_BLACK       :: 9;

    KBTS_FONT_WEIGHT_COUNT       :: 10;
}

kbts_font_width :: u32;
kbts_font_width_enum :: enum u32 {
    KBTS_FONT_WIDTH_UNKNOWN         :: 0;

    KBTS_FONT_WIDTH_ULTRA_CONDENSED :: 1;
    KBTS_FONT_WIDTH_EXTRA_CONDENSED :: 2;
    KBTS_FONT_WIDTH_CONDENSED       :: 3;
    KBTS_FONT_WIDTH_SEMI_CONDENSED  :: 4;
    KBTS_FONT_WIDTH_NORMAL          :: 5;
    KBTS_FONT_WIDTH_SEMI_EXPANDED   :: 6;
    KBTS_FONT_WIDTH_EXPANDED        :: 7;
    KBTS_FONT_WIDTH_EXTRA_EXPANDED  :: 8;
    KBTS_FONT_WIDTH_ULTRA_EXPANDED  :: 9;

    KBTS_FONT_WIDTH_COUNT           :: 10;
}

kbts_glyph_flags :: u32;
kbts_glyph_flags_enum :: enum u32 {
    KBTS_GLYPH_FLAG_ISOL                           :: 1;
    KBTS_GLYPH_FLAG_FINA                           :: 2;
    KBTS_GLYPH_FLAG_FIN2                           :: 4;
    KBTS_GLYPH_FLAG_FIN3                           :: 8;
    KBTS_GLYPH_FLAG_MEDI                           :: 16;
    KBTS_GLYPH_FLAG_MED2                           :: 32;
    KBTS_GLYPH_FLAG_INIT                           :: 64;

    KBTS_GLYPH_FLAG_LJMO                           :: 128;
    KBTS_GLYPH_FLAG_VJMO                           :: 256;
    KBTS_GLYPH_FLAG_TJMO                           :: 512;
    KBTS_GLYPH_FLAG_RPHF                           :: 1024;
    KBTS_GLYPH_FLAG_BLWF                           :: 2048;
    KBTS_GLYPH_FLAG_HALF                           :: 4096;
    KBTS_GLYPH_FLAG_PSTF                           :: 8192;
    KBTS_GLYPH_FLAG_ABVF                           :: 16384;
    KBTS_GLYPH_FLAG_PREF                           :: 32768;
    KBTS_GLYPH_FLAG_NUMR                           :: 65536;
    KBTS_GLYPH_FLAG_FRAC                           :: 131072;
    KBTS_GLYPH_FLAG_DNOM                           :: 262144;
    KBTS_GLYPH_FLAG_CFAR                           :: 524288;

    KBTS_GLYPH_FLAG_DO_NOT_DECOMPOSE               :: 1048576;
    KBTS_GLYPH_FLAG_FIRST_IN_MULTIPLE_SUBSTITUTION :: 2097152;
    KBTS_GLYPH_FLAG_NO_BREAK                       :: 4194304;
    KBTS_GLYPH_FLAG_CURSIVE                        :: 8388608;
    KBTS_GLYPH_FLAG_GENERATED_BY_GSUB              :: 16777216;
    KBTS_GLYPH_FLAG_USED_IN_GPOS                   :: 33554432;

    KBTS_GLYPH_FLAG_STCH_ENDPOINT                  :: 67108864;
    KBTS_GLYPH_FLAG_STCH_EXTENSION                 :: 134217728;

    KBTS_GLYPH_FLAG_LIGATURE                       :: 268435456;
    KBTS_GLYPH_FLAG_MULTIPLE_SUBSTITUTION          :: 536870912;
}

kbts_joining_feature :: u8;
kbts_joining_feature_enum :: enum u32 {
    KBTS_JOINING_FEATURE_NONE  :: 0;

    KBTS_JOINING_FEATURE_ISOL  :: 1;
    KBTS_JOINING_FEATURE_FINA  :: 2;
    KBTS_JOINING_FEATURE_FIN2  :: 3;
    KBTS_JOINING_FEATURE_FIN3  :: 4;
    KBTS_JOINING_FEATURE_MEDI  :: 5;
    KBTS_JOINING_FEATURE_MED2  :: 6;
    KBTS_JOINING_FEATURE_INIT  :: 7;

    KBTS_JOINING_FEATURE_COUNT :: 8;
}

kbts_user_id_generation_mode :: u32;
kbts_user_id_generation_mode_enum :: enum u32 {
    KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX :: 0;
    KBTS_USER_ID_GENERATION_MODE_SOURCE_INDEX    :: 1;

    KBTS_USER_ID_GENERATION_MODE_COUNT           :: 2;
}

kbts_break_config_flags :: u32;
kbts_break_config_flags_enum :: enum u32 {
    KBTS_BREAK_CONFIG_FLAG_NONE                                  :: 0;

    KBTS_BREAK_CONFIG_FLAG_END_OF_TEXT_GENERATES_HARD_LINE_BREAK :: 1;
}

kbts_decode_utf16_flags :: u32;
kbts_decode_utf16_flags_enum :: enum u32 {
    KBTS_DECODE_UTF16_FLAG_NONE       :: 0;

    KBTS_DECODE_UTF16_FLAG_BIG_ENDIAN :: 1;
}

kbts_font_info_string_id :: u32;
kbts_font_info_string_id_enum :: enum u32 {
    KBTS_FONT_INFO_STRING_ID_NONE                              :: 0;
    KBTS_FONT_INFO_STRING_ID_COPYRIGHT                         :: 1;
    KBTS_FONT_INFO_STRING_ID_FAMILY                            :: 2;
    KBTS_FONT_INFO_STRING_ID_SUBFAMILY                         :: 3;
    KBTS_FONT_INFO_STRING_ID_UID                               :: 4;
    KBTS_FONT_INFO_STRING_ID_FULL_NAME                         :: 5;
    KBTS_FONT_INFO_STRING_ID_VERSION                           :: 6;
    KBTS_FONT_INFO_STRING_ID_POSTSCRIPT_NAME                   :: 7;
    KBTS_FONT_INFO_STRING_ID_TRADEMARK                         :: 8;
    KBTS_FONT_INFO_STRING_ID_MANUFACTURER                      :: 9;
    KBTS_FONT_INFO_STRING_ID_DESIGNER                          :: 10;
    KBTS_FONT_INFO_STRING_ID_TYPOGRAPHIC_FAMILY                :: 11;
    KBTS_FONT_INFO_STRING_ID_TYPOGRAPHIC_SUBFAMILY             :: 12;

    KBTS_FONT_INFO_STRING_ID_COUNT0                            :: 13;

    KBTS_FONT_INFO_STRING_ID_DESCRIPTION                       :: 13;
    KBTS_FONT_INFO_STRING_ID_VENDOR_URL                        :: 14;
    KBTS_FONT_INFO_STRING_ID_DESIGNER_URL                      :: 15;
    KBTS_FONT_INFO_STRING_ID_LICENSE                           :: 16;
    KBTS_FONT_INFO_STRING_ID_LICENSE_URL                       :: 17;
    KBTS_FONT_INFO_STRING_ID_COMPATIBLE_FULL_NAME              :: 18;
    KBTS_FONT_INFO_STRING_ID_SAMPLE_TEXT                       :: 19;
    KBTS_FONT_INFO_STRING_ID_POSTSCRIPT_CID_FINDFONT_NAME      :: 20;
    KBTS_FONT_INFO_STRING_ID_WWS_FAMILY_NAME                   :: 21;
    KBTS_FONT_INFO_STRING_ID_WWS_SUBFAMILY_NAME                :: 22;
    KBTS_FONT_INFO_STRING_ID_LIGHT_BACKGROUND_PALETTE          :: 23;
    KBTS_FONT_INFO_STRING_ID_DARK_BACKGROUND_PALETTE           :: 24;
    KBTS_FONT_INFO_STRING_ID_VARIATIONS_POSTSCRIPT_NAME_PREFIX :: 25;

    KBTS_FONT_INFO_STRING_ID_COUNT1                            :: 26;
}

kbts_variation_axis_flags :: u16;
kbts_variation_axis_flags_enum :: enum u32 {
    KBTS_VARIATION_AXIS_FLAG_NONE   :: 0;
    KBTS_VARIATION_AXIS_FLAG_HIDDEN :: 1;
}

kbts_variation_instance_flags :: u32;
kbts_variation_instance_flags_enum :: enum u32 {
    KBTS_VARIATION_INSTANCE_FLAG_NONE                :: 0;
    KBTS_VARIATION_INSTANCE_FLAG_HAS_POSTSCRIPT_NAME :: 1;
}

kbts_unicode_joining_type :: u8;
kbts_unicode_joining_type_enum :: enum u32 {
    KBTS_UNICODE_JOINING_TYPE_NONE        :: 0;
    KBTS_UNICODE_JOINING_TYPE_LEFT        :: 1;
    KBTS_UNICODE_JOINING_TYPE_DUAL        :: 2;
    KBTS_UNICODE_JOINING_TYPE_FORCE       :: 3;
    KBTS_UNICODE_JOINING_TYPE_RIGHT       :: 4;
    KBTS_UNICODE_JOINING_TYPE_TRANSPARENT :: 5;
    KBTS_UNICODE_JOINING_TYPE_COUNT       :: 6;
}

kbts_unicode_flags :: u8;
kbts_unicode_flag_enum :: enum u32 {
    KBTS_UNICODE_FLAG_MODIFIER_COMBINING_MARK :: 1;
    KBTS_UNICODE_FLAG_DEFAULT_IGNORABLE       :: 2;
    KBTS_UNICODE_FLAG_OPEN_BRACKET            :: 4;
    KBTS_UNICODE_FLAG_CLOSE_BRACKET           :: 8;
    KBTS_UNICODE_FLAG_PART_OF_WORD            :: 16;
    KBTS_UNICODE_FLAG_DECIMAL_DIGIT           :: 32;
    KBTS_UNICODE_FLAG_NON_SPACING_MARK        :: 64;

    KBTS_UNICODE_FLAG_MIRRORED                :: 12;
}

kbts_unicode_bidirectional_class :: u8;
kbts_unicode_bidirectional_class_enum :: enum u32 {
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_NI    :: 0;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_BN    :: 1;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_L     :: 2;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_R     :: 3;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_NSM   :: 4;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_AL    :: 5;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_AN    :: 6;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_EN    :: 7;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_ES    :: 8;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_ET    :: 9;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_CS    :: 10;
    KBTS_UNICODE_BIDIRECTIONAL_CLASS_COUNT :: 11;
}

kbts_line_break_class :: u8;
kbts_line_break_class_enum :: enum u32 {
    KBTS_LINE_BREAK_CLASS_Onea          :: 0;
    KBTS_LINE_BREAK_CLASS_Oea           :: 1;
    KBTS_LINE_BREAK_CLASS_Ope           :: 2;
    KBTS_LINE_BREAK_CLASS_BK            :: 3;
    KBTS_LINE_BREAK_CLASS_CR            :: 4;
    KBTS_LINE_BREAK_CLASS_LF            :: 5;
    KBTS_LINE_BREAK_CLASS_NL            :: 6;
    KBTS_LINE_BREAK_CLASS_SP            :: 7;
    KBTS_LINE_BREAK_CLASS_ZW            :: 8;
    KBTS_LINE_BREAK_CLASS_WJ            :: 9;
    KBTS_LINE_BREAK_CLASS_GLnea         :: 10;
    KBTS_LINE_BREAK_CLASS_GLea          :: 11;
    KBTS_LINE_BREAK_CLASS_CLnea         :: 12;
    KBTS_LINE_BREAK_CLASS_CLea          :: 13;
    KBTS_LINE_BREAK_CLASS_CPnea         :: 14;
    KBTS_LINE_BREAK_CLASS_CPea          :: 15;
    KBTS_LINE_BREAK_CLASS_EXnea         :: 16;
    KBTS_LINE_BREAK_CLASS_EXea          :: 17;
    KBTS_LINE_BREAK_CLASS_SY            :: 18;
    KBTS_LINE_BREAK_CLASS_BAnea         :: 19;
    KBTS_LINE_BREAK_CLASS_BAea          :: 20;
    KBTS_LINE_BREAK_CLASS_OPnea         :: 21;
    KBTS_LINE_BREAK_CLASS_OPea          :: 22;
    KBTS_LINE_BREAK_CLASS_QU            :: 23;
    KBTS_LINE_BREAK_CLASS_QUPi          :: 24;
    KBTS_LINE_BREAK_CLASS_QUPf          :: 25;
    KBTS_LINE_BREAK_CLASS_IS            :: 26;
    KBTS_LINE_BREAK_CLASS_NSnea         :: 27;
    KBTS_LINE_BREAK_CLASS_NSea          :: 28;
    KBTS_LINE_BREAK_CLASS_B2            :: 29;
    KBTS_LINE_BREAK_CLASS_CB            :: 30;
    KBTS_LINE_BREAK_CLASS_HY            :: 31;
    KBTS_LINE_BREAK_CLASS_HYPHEN        :: 32;
    KBTS_LINE_BREAK_CLASS_INnea         :: 33;
    KBTS_LINE_BREAK_CLASS_INea          :: 34;
    KBTS_LINE_BREAK_CLASS_BB            :: 35;
    KBTS_LINE_BREAK_CLASS_HL            :: 36;
    KBTS_LINE_BREAK_CLASS_ALnea         :: 37;
    KBTS_LINE_BREAK_CLASS_ALea          :: 38;
    KBTS_LINE_BREAK_CLASS_NU            :: 39;
    KBTS_LINE_BREAK_CLASS_PRnea         :: 40;
    KBTS_LINE_BREAK_CLASS_PRea          :: 41;
    KBTS_LINE_BREAK_CLASS_IDnea         :: 42;
    KBTS_LINE_BREAK_CLASS_IDea          :: 43;
    KBTS_LINE_BREAK_CLASS_IDpe          :: 44;
    KBTS_LINE_BREAK_CLASS_EBnea         :: 45;
    KBTS_LINE_BREAK_CLASS_EBea          :: 46;
    KBTS_LINE_BREAK_CLASS_EM            :: 47;
    KBTS_LINE_BREAK_CLASS_POnea         :: 48;
    KBTS_LINE_BREAK_CLASS_POea          :: 49;
    KBTS_LINE_BREAK_CLASS_JL            :: 50;
    KBTS_LINE_BREAK_CLASS_JV            :: 51;
    KBTS_LINE_BREAK_CLASS_JT            :: 52;
    KBTS_LINE_BREAK_CLASS_H2            :: 53;
    KBTS_LINE_BREAK_CLASS_H3            :: 54;
    KBTS_LINE_BREAK_CLASS_AP            :: 55;
    KBTS_LINE_BREAK_CLASS_AK            :: 56;
    KBTS_LINE_BREAK_CLASS_DOTTED_CIRCLE :: 57;
    KBTS_LINE_BREAK_CLASS_AS            :: 58;
    KBTS_LINE_BREAK_CLASS_VF            :: 59;
    KBTS_LINE_BREAK_CLASS_VI            :: 60;
    KBTS_LINE_BREAK_CLASS_RI            :: 61;

    KBTS_LINE_BREAK_CLASS_COUNT         :: 62;

    KBTS_LINE_BREAK_CLASS_CM            :: 63;
    KBTS_LINE_BREAK_CLASS_ZWJ           :: 64;

    KBTS_LINE_BREAK_CLASS_CJ            :: 65;

    KBTS_LINE_BREAK_CLASS_SOT           :: 66;
    KBTS_LINE_BREAK_CLASS_EOT           :: 67;
}

// @Cleanup: Merge EX and FO.
kbts_word_break_class :: u8;
kbts_word_break_class_enum :: enum u32 {
    KBTS_WORD_BREAK_CLASS_Onep  :: 0;
    KBTS_WORD_BREAK_CLASS_Oep   :: 1;
    KBTS_WORD_BREAK_CLASS_CR    :: 2;
    KBTS_WORD_BREAK_CLASS_LF    :: 3;
    KBTS_WORD_BREAK_CLASS_NL    :: 4;
    KBTS_WORD_BREAK_CLASS_EX    :: 5;
    KBTS_WORD_BREAK_CLASS_ZWJ   :: 6;
    KBTS_WORD_BREAK_CLASS_RI    :: 7;
    KBTS_WORD_BREAK_CLASS_FO    :: 8;
    KBTS_WORD_BREAK_CLASS_KA    :: 9;
    KBTS_WORD_BREAK_CLASS_HL    :: 10;
    KBTS_WORD_BREAK_CLASS_ALnep :: 11;
    KBTS_WORD_BREAK_CLASS_ALep  :: 12;
    KBTS_WORD_BREAK_CLASS_SQ    :: 13;
    KBTS_WORD_BREAK_CLASS_DQ    :: 14;
    KBTS_WORD_BREAK_CLASS_MNL   :: 15;
    KBTS_WORD_BREAK_CLASS_ML    :: 16;
    KBTS_WORD_BREAK_CLASS_MN    :: 17;
    KBTS_WORD_BREAK_CLASS_NM    :: 18;
    KBTS_WORD_BREAK_CLASS_ENL   :: 19;
    KBTS_WORD_BREAK_CLASS_WSS   :: 20;

    KBTS_WORD_BREAK_CLASS_SOT   :: 21;
}

// Unicode defines scripts and languages.
// A language belongs to a single script, and a script belongs to a single writing system.
// On top of these, OpenType defines shapers, which are basically just designations for
// specific code paths that are taken depending on which script is being shapen.
//
// Some scripts, like Latin and Cyrillic, need relatively few operations, while complex
// scripts like Arabic and Indic scripts have specific processing steps that need to happen
// in order to obtain a correct result.
//
// These sequences of operations are _not_ described in the font file itself. The shaping
// code needs to know which script it is shaping, and implement all of those passes itself.
// That is why you, as a user, have to care about this.
//
// When creating shape_config, you can either pass in a known script, or you can specify
// SCRIPT_DONT_KNOW and let the library figure it out.
// While SCRIPT_DONT_KNOW may look appealing, it is worth noting that we can only infer
// the _script_, and not the language, of the text you pass in.
// This means that you might miss out on language-specific features when you use it.
kbts_shaper :: u32;
kbts_shaper_enum :: enum u32 {
    KBTS_SHAPER_DEFAULT :: 0;
    KBTS_SHAPER_ARABIC  :: 1;
    KBTS_SHAPER_HANGUL  :: 2;
    KBTS_SHAPER_HEBREW  :: 3;
    KBTS_SHAPER_INDIC   :: 4;
    KBTS_SHAPER_KHMER   :: 5;
    KBTS_SHAPER_MYANMAR :: 6;
    KBTS_SHAPER_TIBETAN :: 7;
    KBTS_SHAPER_USE     :: 8;

    KBTS_SHAPER_COUNT   :: 9;
}

kbts_script_tag :: u32;
kbts_script_tag_enum :: enum u32 {
    KBTS_SCRIPT_TAG_DONT_KNOW                 :: 538976288;
    KBTS_SCRIPT_TAG_ADLAM                     :: 1835820129;
    KBTS_SCRIPT_TAG_AHOM                      :: 1836017761;
    KBTS_SCRIPT_TAG_ANATOLIAN_HIEROGLYPHS     :: 2004184168;
    KBTS_SCRIPT_TAG_ARABIC                    :: 1650553441;
    KBTS_SCRIPT_TAG_ARMENIAN                  :: 1852666465;
    KBTS_SCRIPT_TAG_AVESTAN                   :: 1953724001;
    KBTS_SCRIPT_TAG_BALINESE                  :: 1768710498;
    KBTS_SCRIPT_TAG_BAMUM                     :: 1970102626;
    KBTS_SCRIPT_TAG_BASSA_VAH                 :: 1936941410;
    KBTS_SCRIPT_TAG_BATAK                     :: 1802789218;
    KBTS_SCRIPT_TAG_BENGALI                   :: 845639266;
    KBTS_SCRIPT_TAG_BHAIKSUKI                 :: 1936418914;
    KBTS_SCRIPT_TAG_BOPOMOFO                  :: 1869639522;
    KBTS_SCRIPT_TAG_BRAHMI                    :: 1751216738;
    KBTS_SCRIPT_TAG_BUGINESE                  :: 1768387938;
    KBTS_SCRIPT_TAG_BUHID                     :: 1684567394;
    KBTS_SCRIPT_TAG_CANADIAN_SYLLABICS        :: 1936613731;
    KBTS_SCRIPT_TAG_CARIAN                    :: 1769103715;
    KBTS_SCRIPT_TAG_CAUCASIAN_ALBANIAN        :: 1651009377;
    KBTS_SCRIPT_TAG_CHAKMA                    :: 1835753827;
    KBTS_SCRIPT_TAG_CHAM                      :: 1835100259;
    KBTS_SCRIPT_TAG_CHEROKEE                  :: 1919248483;
    KBTS_SCRIPT_TAG_CHORASMIAN                :: 1936877667;
    KBTS_SCRIPT_TAG_CJK_IDEOGRAPHIC           :: 1768841576;
    KBTS_SCRIPT_TAG_COPTIC                    :: 1953525603;
    KBTS_SCRIPT_TAG_CYPRIOT_SYLLABARY         :: 1953656931;
    KBTS_SCRIPT_TAG_CYPRO_MINOAN              :: 1852665955;
    KBTS_SCRIPT_TAG_CYRILLIC                  :: 1819441507;
    KBTS_SCRIPT_TAG_DEFAULT                   :: 1414284868;
    KBTS_SCRIPT_TAG_DEFAULT2                  :: 1414284868;
    KBTS_SCRIPT_TAG_DESERET                   :: 1953657700;
    KBTS_SCRIPT_TAG_DEVANAGARI                :: 846620004;
    KBTS_SCRIPT_TAG_DIVES_AKURU               :: 1801546084;
    KBTS_SCRIPT_TAG_DOGRA                     :: 1919381348;
    KBTS_SCRIPT_TAG_DUPLOYAN                  :: 1819309412;
    KBTS_SCRIPT_TAG_EGYPTIAN_HIEROGLYPHS      :: 1887004517;
    KBTS_SCRIPT_TAG_ELBASAN                   :: 1633840229;
    KBTS_SCRIPT_TAG_ELYMAIC                   :: 1836674149;
    KBTS_SCRIPT_TAG_ETHIOPIC                  :: 1768453221;
    KBTS_SCRIPT_TAG_GARAY                     :: 1634885991;
    KBTS_SCRIPT_TAG_GEORGIAN                  :: 1919903079;
    KBTS_SCRIPT_TAG_GLAGOLITIC                :: 1734437991;
    KBTS_SCRIPT_TAG_GOTHIC                    :: 1752461159;
    KBTS_SCRIPT_TAG_GRANTHA                   :: 1851880039;
    KBTS_SCRIPT_TAG_GREEK                     :: 1801810535;
    KBTS_SCRIPT_TAG_GUJARATI                  :: 846359143;
    KBTS_SCRIPT_TAG_GUNJALA_GONDI             :: 1735290727;
    KBTS_SCRIPT_TAG_GURMUKHI                  :: 846361959;
    KBTS_SCRIPT_TAG_GURUNG_KHEMA              :: 1751872871;
    KBTS_SCRIPT_TAG_HANGUL                    :: 1735287144;
    KBTS_SCRIPT_TAG_HANIFI_ROHINGYA           :: 1734897522;
    KBTS_SCRIPT_TAG_HANUNOO                   :: 1869504872;
    KBTS_SCRIPT_TAG_HATRAN                    :: 1920229736;
    KBTS_SCRIPT_TAG_HEBREW                    :: 1919051112;
    KBTS_SCRIPT_TAG_HIRAGANA                  :: 1634623851;
    KBTS_SCRIPT_TAG_IMPERIAL_ARAMAIC          :: 1768780385;
    KBTS_SCRIPT_TAG_INSCRIPTIONAL_PAHLAVI     :: 1768712304;
    KBTS_SCRIPT_TAG_INSCRIPTIONAL_PARTHIAN    :: 1769239152;
    KBTS_SCRIPT_TAG_JAVANESE                  :: 1635148138;
    KBTS_SCRIPT_TAG_KAITHI                    :: 1768453227;
    KBTS_SCRIPT_TAG_KANNADA                   :: 845442667;
    KBTS_SCRIPT_TAG_KATAKANA                  :: 1634623851;
    KBTS_SCRIPT_TAG_KAWI                      :: 1769431403;
    KBTS_SCRIPT_TAG_KAYAH_LI                  :: 1768710507;
    KBTS_SCRIPT_TAG_KHAROSHTHI                :: 1918986347;
    KBTS_SCRIPT_TAG_KHITAN_SMALL_SCRIPT       :: 1937009003;
    KBTS_SCRIPT_TAG_KHMER                     :: 1919772779;
    KBTS_SCRIPT_TAG_KHOJKI                    :: 1785686123;
    KBTS_SCRIPT_TAG_KHUDAWADI                 :: 1684957555;
    KBTS_SCRIPT_TAG_KIRAT_RAI                 :: 1767993963;
    KBTS_SCRIPT_TAG_LAO                       :: 544170348;
    KBTS_SCRIPT_TAG_LATIN                     :: 1853120876;
    KBTS_SCRIPT_TAG_LEPCHA                    :: 1668310380;
    KBTS_SCRIPT_TAG_LIMBU                     :: 1651337580;
    KBTS_SCRIPT_TAG_LINEAR_A                  :: 1634625900;
    KBTS_SCRIPT_TAG_LINEAR_B                  :: 1651403116;
    KBTS_SCRIPT_TAG_LISU                      :: 1970497900;
    KBTS_SCRIPT_TAG_LYCIAN                    :: 1768126828;
    KBTS_SCRIPT_TAG_LYDIAN                    :: 1768192364;
    KBTS_SCRIPT_TAG_MAHAJANI                  :: 1785225581;
    KBTS_SCRIPT_TAG_MAKASAR                   :: 1634427245;
    KBTS_SCRIPT_TAG_MALAYALAM                 :: 846031981;
    KBTS_SCRIPT_TAG_MANDAIC                   :: 1684955501;
    KBTS_SCRIPT_TAG_MANICHAEAN                :: 1768841581;
    KBTS_SCRIPT_TAG_MARCHEN                   :: 1668440429;
    KBTS_SCRIPT_TAG_MASARAM_GONDI             :: 1835954023;
    KBTS_SCRIPT_TAG_MEDEFAIDRIN               :: 1717855597;
    KBTS_SCRIPT_TAG_MEETEI_MAYEK              :: 1768256621;
    KBTS_SCRIPT_TAG_MENDE_KIKAKUI             :: 1684956525;
    KBTS_SCRIPT_TAG_MEROITIC_CURSIVE          :: 1668441453;
    KBTS_SCRIPT_TAG_MEROITIC_HIEROGLYPHS      :: 1869768045;
    KBTS_SCRIPT_TAG_MIAO                      :: 1685220464;
    KBTS_SCRIPT_TAG_MODI                      :: 1768189805;
    KBTS_SCRIPT_TAG_MONGOLIAN                 :: 1735290733;
    KBTS_SCRIPT_TAG_MRO                       :: 1869574765;
    KBTS_SCRIPT_TAG_MULTANI                   :: 1953265005;
    KBTS_SCRIPT_TAG_MYANMAR                   :: 846035309;
    KBTS_SCRIPT_TAG_NABATAEAN                 :: 1952539246;
    KBTS_SCRIPT_TAG_NAG_MUNDARI               :: 1835491694;
    KBTS_SCRIPT_TAG_NANDINAGARI               :: 1684955502;
    KBTS_SCRIPT_TAG_NEWA                      :: 1635214702;
    KBTS_SCRIPT_TAG_NEW_TAI_LUE               :: 1970037108;
    KBTS_SCRIPT_TAG_NKO                       :: 544172910;
    KBTS_SCRIPT_TAG_NUSHU                     :: 1969779566;
    KBTS_SCRIPT_TAG_NYIAKENG_PUACHUE_HMONG    :: 1886285160;
    KBTS_SCRIPT_TAG_OGHAM                     :: 1835100015;
    KBTS_SCRIPT_TAG_OL_CHIKI                  :: 1801677935;
    KBTS_SCRIPT_TAG_OL_ONAL                   :: 1868656239;
    KBTS_SCRIPT_TAG_OLD_ITALIC                :: 1818326121;
    KBTS_SCRIPT_TAG_OLD_HUNGARIAN             :: 1735292264;
    KBTS_SCRIPT_TAG_OLD_NORTH_ARABIAN         :: 1651663214;
    KBTS_SCRIPT_TAG_OLD_PERMIC                :: 1836213616;
    KBTS_SCRIPT_TAG_OLD_PERSIAN_CUNEIFORM     :: 1868918904;
    KBTS_SCRIPT_TAG_OLD_SOGDIAN               :: 1869049715;
    KBTS_SCRIPT_TAG_OLD_SOUTH_ARABIAN         :: 1651663219;
    KBTS_SCRIPT_TAG_OLD_TURKIC                :: 1751872111;
    KBTS_SCRIPT_TAG_OLD_UYGHUR                :: 1919382895;
    KBTS_SCRIPT_TAG_ODIA                      :: 846819951;
    KBTS_SCRIPT_TAG_OSAGE                     :: 1701278575;
    KBTS_SCRIPT_TAG_OSMANYA                   :: 1634562927;
    KBTS_SCRIPT_TAG_PAHAWH_HMONG              :: 1735290216;
    KBTS_SCRIPT_TAG_PALMYRENE                 :: 1835819376;
    KBTS_SCRIPT_TAG_PAU_CIN_HAU               :: 1668637040;
    KBTS_SCRIPT_TAG_PHAGS_PA                  :: 1734436976;
    KBTS_SCRIPT_TAG_PHOENICIAN                :: 2020501616;
    KBTS_SCRIPT_TAG_PSALTER_PAHLAVI           :: 1886152816;
    KBTS_SCRIPT_TAG_REJANG                    :: 1735289458;
    KBTS_SCRIPT_TAG_RUNIC                     :: 1919841650;
    KBTS_SCRIPT_TAG_SAMARITAN                 :: 1919770995;
    KBTS_SCRIPT_TAG_SAURASHTRA                :: 1920295283;
    KBTS_SCRIPT_TAG_SHARADA                   :: 1685219443;
    KBTS_SCRIPT_TAG_SHAVIAN                   :: 2002872435;
    KBTS_SCRIPT_TAG_SIDDHAM                   :: 1684302195;
    KBTS_SCRIPT_TAG_SIGN_WRITING              :: 2003724147;
    KBTS_SCRIPT_TAG_SOGDIAN                   :: 1684500339;
    KBTS_SCRIPT_TAG_SINHALA                   :: 1752066419;
    KBTS_SCRIPT_TAG_SORA_SOMPENG              :: 1634889587;
    KBTS_SCRIPT_TAG_SOYOMBO                   :: 1870229363;
    KBTS_SCRIPT_TAG_SUMERO_AKKADIAN_CUNEIFORM :: 2020963192;
    KBTS_SCRIPT_TAG_SUNDANESE                 :: 1684960627;
    KBTS_SCRIPT_TAG_SUNUWAR                   :: 1970173299;
    KBTS_SCRIPT_TAG_SYLOTI_NAGRI              :: 1869379955;
    KBTS_SCRIPT_TAG_SYRIAC                    :: 1668446579;
    KBTS_SCRIPT_TAG_TAGALOG                   :: 1735157620;
    KBTS_SCRIPT_TAG_TAGBANWA                  :: 1650942324;
    KBTS_SCRIPT_TAG_TAI_LE                    :: 1701601652;
    KBTS_SCRIPT_TAG_TAI_THAM                  :: 1634623852;
    KBTS_SCRIPT_TAG_TAI_VIET                  :: 1953915252;
    KBTS_SCRIPT_TAG_TAKRI                     :: 1919639924;
    KBTS_SCRIPT_TAG_TAMIL                     :: 845966708;
    KBTS_SCRIPT_TAG_TANGSA                    :: 1634954868;
    KBTS_SCRIPT_TAG_TANGUT                    :: 1735287156;
    KBTS_SCRIPT_TAG_TELUGU                    :: 845964660;
    KBTS_SCRIPT_TAG_THAANA                    :: 1633773684;
    KBTS_SCRIPT_TAG_THAI                      :: 1767991412;
    KBTS_SCRIPT_TAG_TIBETAN                   :: 1952606580;
    KBTS_SCRIPT_TAG_TIFINAGH                  :: 1735288436;
    KBTS_SCRIPT_TAG_TIRHUTA                   :: 1752328564;
    KBTS_SCRIPT_TAG_TODHRI                    :: 1919184756;
    KBTS_SCRIPT_TAG_TOTO                      :: 1869901684;
    KBTS_SCRIPT_TAG_TULU_TIGALARI             :: 1735685492;
    KBTS_SCRIPT_TAG_UGARITIC_CUNEIFORM        :: 1918986101;
    KBTS_SCRIPT_TAG_VAI                       :: 543777142;
    KBTS_SCRIPT_TAG_VITHKUQI                  :: 1752459638;
    KBTS_SCRIPT_TAG_WANCHO                    :: 1869112183;
    KBTS_SCRIPT_TAG_WARANG_CITI               :: 1634886007;
    KBTS_SCRIPT_TAG_YEZIDI                    :: 1769629049;
    KBTS_SCRIPT_TAG_YI                        :: 538995065;
    KBTS_SCRIPT_TAG_ZANABAZAR_SQUARE          :: 1651401082;
}

kbts_script :: u32;
kbts_script_enum :: enum u32 {
    KBTS_SCRIPT_DONT_KNOW                 :: 0;
    KBTS_SCRIPT_ADLAM                     :: 1;
    KBTS_SCRIPT_AHOM                      :: 2;
    KBTS_SCRIPT_ANATOLIAN_HIEROGLYPHS     :: 3;
    KBTS_SCRIPT_ARABIC                    :: 4;
    KBTS_SCRIPT_ARMENIAN                  :: 5;
    KBTS_SCRIPT_AVESTAN                   :: 6;
    KBTS_SCRIPT_BALINESE                  :: 7;
    KBTS_SCRIPT_BAMUM                     :: 8;
    KBTS_SCRIPT_BASSA_VAH                 :: 9;
    KBTS_SCRIPT_BATAK                     :: 10;
    KBTS_SCRIPT_BENGALI                   :: 11;
    KBTS_SCRIPT_BHAIKSUKI                 :: 12;
    KBTS_SCRIPT_BOPOMOFO                  :: 13;
    KBTS_SCRIPT_BRAHMI                    :: 14;
    KBTS_SCRIPT_BUGINESE                  :: 15;
    KBTS_SCRIPT_BUHID                     :: 16;
    KBTS_SCRIPT_CANADIAN_SYLLABICS        :: 17;
    KBTS_SCRIPT_CARIAN                    :: 18;
    KBTS_SCRIPT_CAUCASIAN_ALBANIAN        :: 19;
    KBTS_SCRIPT_CHAKMA                    :: 20;
    KBTS_SCRIPT_CHAM                      :: 21;
    KBTS_SCRIPT_CHEROKEE                  :: 22;
    KBTS_SCRIPT_CHORASMIAN                :: 23;
    KBTS_SCRIPT_CJK_IDEOGRAPHIC           :: 24;
    KBTS_SCRIPT_COPTIC                    :: 25;
    KBTS_SCRIPT_CYPRIOT_SYLLABARY         :: 26;
    KBTS_SCRIPT_CYPRO_MINOAN              :: 27;
    KBTS_SCRIPT_CYRILLIC                  :: 28;
    KBTS_SCRIPT_DEFAULT                   :: 29;
    KBTS_SCRIPT_DEFAULT2                  :: 30;
    KBTS_SCRIPT_DESERET                   :: 31;
    KBTS_SCRIPT_DEVANAGARI                :: 32;
    KBTS_SCRIPT_DIVES_AKURU               :: 33;
    KBTS_SCRIPT_DOGRA                     :: 34;
    KBTS_SCRIPT_DUPLOYAN                  :: 35;
    KBTS_SCRIPT_EGYPTIAN_HIEROGLYPHS      :: 36;
    KBTS_SCRIPT_ELBASAN                   :: 37;
    KBTS_SCRIPT_ELYMAIC                   :: 38;
    KBTS_SCRIPT_ETHIOPIC                  :: 39;
    KBTS_SCRIPT_GARAY                     :: 40;
    KBTS_SCRIPT_GEORGIAN                  :: 41;
    KBTS_SCRIPT_GLAGOLITIC                :: 42;
    KBTS_SCRIPT_GOTHIC                    :: 43;
    KBTS_SCRIPT_GRANTHA                   :: 44;
    KBTS_SCRIPT_GREEK                     :: 45;
    KBTS_SCRIPT_GUJARATI                  :: 46;
    KBTS_SCRIPT_GUNJALA_GONDI             :: 47;
    KBTS_SCRIPT_GURMUKHI                  :: 48;
    KBTS_SCRIPT_GURUNG_KHEMA              :: 49;
    KBTS_SCRIPT_HANGUL                    :: 50;
    KBTS_SCRIPT_HANIFI_ROHINGYA           :: 51;
    KBTS_SCRIPT_HANUNOO                   :: 52;
    KBTS_SCRIPT_HATRAN                    :: 53;
    KBTS_SCRIPT_HEBREW                    :: 54;
    KBTS_SCRIPT_HIRAGANA                  :: 55;
    KBTS_SCRIPT_IMPERIAL_ARAMAIC          :: 56;
    KBTS_SCRIPT_INSCRIPTIONAL_PAHLAVI     :: 57;
    KBTS_SCRIPT_INSCRIPTIONAL_PARTHIAN    :: 58;
    KBTS_SCRIPT_JAVANESE                  :: 59;
    KBTS_SCRIPT_KAITHI                    :: 60;
    KBTS_SCRIPT_KANNADA                   :: 61;
    KBTS_SCRIPT_KATAKANA                  :: 62;
    KBTS_SCRIPT_KAWI                      :: 63;
    KBTS_SCRIPT_KAYAH_LI                  :: 64;
    KBTS_SCRIPT_KHAROSHTHI                :: 65;
    KBTS_SCRIPT_KHITAN_SMALL_SCRIPT       :: 66;
    KBTS_SCRIPT_KHMER                     :: 67;
    KBTS_SCRIPT_KHOJKI                    :: 68;
    KBTS_SCRIPT_KHUDAWADI                 :: 69;
    KBTS_SCRIPT_KIRAT_RAI                 :: 70;
    KBTS_SCRIPT_LAO                       :: 71;
    KBTS_SCRIPT_LATIN                     :: 72;
    KBTS_SCRIPT_LEPCHA                    :: 73;
    KBTS_SCRIPT_LIMBU                     :: 74;
    KBTS_SCRIPT_LINEAR_A                  :: 75;
    KBTS_SCRIPT_LINEAR_B                  :: 76;
    KBTS_SCRIPT_LISU                      :: 77;
    KBTS_SCRIPT_LYCIAN                    :: 78;
    KBTS_SCRIPT_LYDIAN                    :: 79;
    KBTS_SCRIPT_MAHAJANI                  :: 80;
    KBTS_SCRIPT_MAKASAR                   :: 81;
    KBTS_SCRIPT_MALAYALAM                 :: 82;
    KBTS_SCRIPT_MANDAIC                   :: 83;
    KBTS_SCRIPT_MANICHAEAN                :: 84;
    KBTS_SCRIPT_MARCHEN                   :: 85;
    KBTS_SCRIPT_MASARAM_GONDI             :: 86;
    KBTS_SCRIPT_MEDEFAIDRIN               :: 87;
    KBTS_SCRIPT_MEETEI_MAYEK              :: 88;
    KBTS_SCRIPT_MENDE_KIKAKUI             :: 89;
    KBTS_SCRIPT_MEROITIC_CURSIVE          :: 90;
    KBTS_SCRIPT_MEROITIC_HIEROGLYPHS      :: 91;
    KBTS_SCRIPT_MIAO                      :: 92;
    KBTS_SCRIPT_MODI                      :: 93;
    KBTS_SCRIPT_MONGOLIAN                 :: 94;
    KBTS_SCRIPT_MRO                       :: 95;
    KBTS_SCRIPT_MULTANI                   :: 96;
    KBTS_SCRIPT_MYANMAR                   :: 97;
    KBTS_SCRIPT_NABATAEAN                 :: 98;
    KBTS_SCRIPT_NAG_MUNDARI               :: 99;
    KBTS_SCRIPT_NANDINAGARI               :: 100;
    KBTS_SCRIPT_NEWA                      :: 101;
    KBTS_SCRIPT_NEW_TAI_LUE               :: 102;
    KBTS_SCRIPT_NKO                       :: 103;
    KBTS_SCRIPT_NUSHU                     :: 104;
    KBTS_SCRIPT_NYIAKENG_PUACHUE_HMONG    :: 105;
    KBTS_SCRIPT_OGHAM                     :: 106;
    KBTS_SCRIPT_OL_CHIKI                  :: 107;
    KBTS_SCRIPT_OL_ONAL                   :: 108;
    KBTS_SCRIPT_OLD_ITALIC                :: 109;
    KBTS_SCRIPT_OLD_HUNGARIAN             :: 110;
    KBTS_SCRIPT_OLD_NORTH_ARABIAN         :: 111;
    KBTS_SCRIPT_OLD_PERMIC                :: 112;
    KBTS_SCRIPT_OLD_PERSIAN_CUNEIFORM     :: 113;
    KBTS_SCRIPT_OLD_SOGDIAN               :: 114;
    KBTS_SCRIPT_OLD_SOUTH_ARABIAN         :: 115;
    KBTS_SCRIPT_OLD_TURKIC                :: 116;
    KBTS_SCRIPT_OLD_UYGHUR                :: 117;
    KBTS_SCRIPT_ODIA                      :: 118;
    KBTS_SCRIPT_OSAGE                     :: 119;
    KBTS_SCRIPT_OSMANYA                   :: 120;
    KBTS_SCRIPT_PAHAWH_HMONG              :: 121;
    KBTS_SCRIPT_PALMYRENE                 :: 122;
    KBTS_SCRIPT_PAU_CIN_HAU               :: 123;
    KBTS_SCRIPT_PHAGS_PA                  :: 124;
    KBTS_SCRIPT_PHOENICIAN                :: 125;
    KBTS_SCRIPT_PSALTER_PAHLAVI           :: 126;
    KBTS_SCRIPT_REJANG                    :: 127;
    KBTS_SCRIPT_RUNIC                     :: 128;
    KBTS_SCRIPT_SAMARITAN                 :: 129;
    KBTS_SCRIPT_SAURASHTRA                :: 130;
    KBTS_SCRIPT_SHARADA                   :: 131;
    KBTS_SCRIPT_SHAVIAN                   :: 132;
    KBTS_SCRIPT_SIDDHAM                   :: 133;
    KBTS_SCRIPT_SIGN_WRITING              :: 134;
    KBTS_SCRIPT_SOGDIAN                   :: 135;
    KBTS_SCRIPT_SINHALA                   :: 136;
    KBTS_SCRIPT_SORA_SOMPENG              :: 137;
    KBTS_SCRIPT_SOYOMBO                   :: 138;
    KBTS_SCRIPT_SUMERO_AKKADIAN_CUNEIFORM :: 139;
    KBTS_SCRIPT_SUNDANESE                 :: 140;
    KBTS_SCRIPT_SUNUWAR                   :: 141;
    KBTS_SCRIPT_SYLOTI_NAGRI              :: 142;
    KBTS_SCRIPT_SYRIAC                    :: 143;
    KBTS_SCRIPT_TAGALOG                   :: 144;
    KBTS_SCRIPT_TAGBANWA                  :: 145;
    KBTS_SCRIPT_TAI_LE                    :: 146;
    KBTS_SCRIPT_TAI_THAM                  :: 147;
    KBTS_SCRIPT_TAI_VIET                  :: 148;
    KBTS_SCRIPT_TAKRI                     :: 149;
    KBTS_SCRIPT_TAMIL                     :: 150;
    KBTS_SCRIPT_TANGSA                    :: 151;
    KBTS_SCRIPT_TANGUT                    :: 152;
    KBTS_SCRIPT_TELUGU                    :: 153;
    KBTS_SCRIPT_THAANA                    :: 154;
    KBTS_SCRIPT_THAI                      :: 155;
    KBTS_SCRIPT_TIBETAN                   :: 156;
    KBTS_SCRIPT_TIFINAGH                  :: 157;
    KBTS_SCRIPT_TIRHUTA                   :: 158;
    KBTS_SCRIPT_TODHRI                    :: 159;
    KBTS_SCRIPT_TOTO                      :: 160;
    KBTS_SCRIPT_TULU_TIGALARI             :: 161;
    KBTS_SCRIPT_UGARITIC_CUNEIFORM        :: 162;
    KBTS_SCRIPT_VAI                       :: 163;
    KBTS_SCRIPT_VITHKUQI                  :: 164;
    KBTS_SCRIPT_WANCHO                    :: 165;
    KBTS_SCRIPT_WARANG_CITI               :: 166;
    KBTS_SCRIPT_YEZIDI                    :: 167;
    KBTS_SCRIPT_YI                        :: 168;
    KBTS_SCRIPT_ZANABAZAR_SQUARE          :: 169;
    KBTS_SCRIPT_COUNT                     :: 170;
}

kbts_feature_tag :: u32;
kbts_feature_tag_enum :: enum u32 {
    KBTS_FEATURE_TAG_UNREGISTERED :: 0;
    KBTS_FEATURE_TAG_isol         :: 1819243369;
    KBTS_FEATURE_TAG_fina         :: 1634625894;
    KBTS_FEATURE_TAG_fin2         :: 846096742;
    KBTS_FEATURE_TAG_fin3         :: 862873958;
    KBTS_FEATURE_TAG_medi         :: 1768187245;
    KBTS_FEATURE_TAG_med2         :: 845440365;
    KBTS_FEATURE_TAG_init         :: 1953066601;
    KBTS_FEATURE_TAG_ljmo         :: 1869441644;
    KBTS_FEATURE_TAG_vjmo         :: 1869441654;
    KBTS_FEATURE_TAG_tjmo         :: 1869441652;
    KBTS_FEATURE_TAG_rphf         :: 1718120562;
    KBTS_FEATURE_TAG_blwf         :: 1719102562;
    KBTS_FEATURE_TAG_half         :: 1718378856;
    KBTS_FEATURE_TAG_pstf         :: 1718907760;
    KBTS_FEATURE_TAG_abvf         :: 1719034465;
    KBTS_FEATURE_TAG_pref         :: 1717924464;
    KBTS_FEATURE_TAG_numr         :: 1919776110;
    KBTS_FEATURE_TAG_frac         :: 1667330662;
    KBTS_FEATURE_TAG_dnom         :: 1836019300;
    KBTS_FEATURE_TAG_cfar         :: 1918985827;
    KBTS_FEATURE_TAG_aalt         :: 1953259873;
    KBTS_FEATURE_TAG_abvm         :: 1836474977;
    KBTS_FEATURE_TAG_abvs         :: 1937138273;
    KBTS_FEATURE_TAG_afrc         :: 1668441697;
    KBTS_FEATURE_TAG_akhn         :: 1852336993;
    KBTS_FEATURE_TAG_apkn         :: 1852534881;
    KBTS_FEATURE_TAG_blwm         :: 1836543074;
    KBTS_FEATURE_TAG_blws         :: 1937206370;
    KBTS_FEATURE_TAG_calt         :: 1953259875;
    KBTS_FEATURE_TAG_case         :: 1702060387;
    KBTS_FEATURE_TAG_ccmp         :: 1886217059;
    KBTS_FEATURE_TAG_chws         :: 1937205347;
    KBTS_FEATURE_TAG_cjct         :: 1952672355;
    KBTS_FEATURE_TAG_clig         :: 1734962275;
    KBTS_FEATURE_TAG_cpct         :: 1952673891;
    KBTS_FEATURE_TAG_cpsp         :: 1886613603;
    KBTS_FEATURE_TAG_cswh         :: 1752658787;
    KBTS_FEATURE_TAG_curs         :: 1936880995;
    KBTS_FEATURE_TAG_cv01         :: 825259619;
    KBTS_FEATURE_TAG_cv02         :: 842036835;
    KBTS_FEATURE_TAG_cv03         :: 858814051;
    KBTS_FEATURE_TAG_cv04         :: 875591267;
    KBTS_FEATURE_TAG_cv05         :: 892368483;
    KBTS_FEATURE_TAG_cv06         :: 909145699;
    KBTS_FEATURE_TAG_cv07         :: 925922915;
    KBTS_FEATURE_TAG_cv08         :: 942700131;
    KBTS_FEATURE_TAG_cv09         :: 959477347;
    KBTS_FEATURE_TAG_cv10         :: 808547939;
    KBTS_FEATURE_TAG_cv11         :: 825325155;
    KBTS_FEATURE_TAG_cv12         :: 842102371;
    KBTS_FEATURE_TAG_cv13         :: 858879587;
    KBTS_FEATURE_TAG_cv14         :: 875656803;
    KBTS_FEATURE_TAG_cv15         :: 892434019;
    KBTS_FEATURE_TAG_cv16         :: 909211235;
    KBTS_FEATURE_TAG_cv17         :: 925988451;
    KBTS_FEATURE_TAG_cv18         :: 942765667;
    KBTS_FEATURE_TAG_cv19         :: 959542883;
    KBTS_FEATURE_TAG_cv20         :: 808613475;
    KBTS_FEATURE_TAG_cv21         :: 825390691;
    KBTS_FEATURE_TAG_cv22         :: 842167907;
    KBTS_FEATURE_TAG_cv23         :: 858945123;
    KBTS_FEATURE_TAG_cv24         :: 875722339;
    KBTS_FEATURE_TAG_cv25         :: 892499555;
    KBTS_FEATURE_TAG_cv26         :: 909276771;
    KBTS_FEATURE_TAG_cv27         :: 926053987;
    KBTS_FEATURE_TAG_cv28         :: 942831203;
    KBTS_FEATURE_TAG_cv29         :: 959608419;
    KBTS_FEATURE_TAG_cv30         :: 808679011;
    KBTS_FEATURE_TAG_cv31         :: 825456227;
    KBTS_FEATURE_TAG_cv32         :: 842233443;
    KBTS_FEATURE_TAG_cv33         :: 859010659;
    KBTS_FEATURE_TAG_cv34         :: 875787875;
    KBTS_FEATURE_TAG_cv35         :: 892565091;
    KBTS_FEATURE_TAG_cv36         :: 909342307;
    KBTS_FEATURE_TAG_cv37         :: 926119523;
    KBTS_FEATURE_TAG_cv38         :: 942896739;
    KBTS_FEATURE_TAG_cv39         :: 959673955;
    KBTS_FEATURE_TAG_cv40         :: 808744547;
    KBTS_FEATURE_TAG_cv41         :: 825521763;
    KBTS_FEATURE_TAG_cv42         :: 842298979;
    KBTS_FEATURE_TAG_cv43         :: 859076195;
    KBTS_FEATURE_TAG_cv44         :: 875853411;
    KBTS_FEATURE_TAG_cv45         :: 892630627;
    KBTS_FEATURE_TAG_cv46         :: 909407843;
    KBTS_FEATURE_TAG_cv47         :: 926185059;
    KBTS_FEATURE_TAG_cv48         :: 942962275;
    KBTS_FEATURE_TAG_cv49         :: 959739491;
    KBTS_FEATURE_TAG_cv50         :: 808810083;
    KBTS_FEATURE_TAG_cv51         :: 825587299;
    KBTS_FEATURE_TAG_cv52         :: 842364515;
    KBTS_FEATURE_TAG_cv53         :: 859141731;
    KBTS_FEATURE_TAG_cv54         :: 875918947;
    KBTS_FEATURE_TAG_cv55         :: 892696163;
    KBTS_FEATURE_TAG_cv56         :: 909473379;
    KBTS_FEATURE_TAG_cv57         :: 926250595;
    KBTS_FEATURE_TAG_cv58         :: 943027811;
    KBTS_FEATURE_TAG_cv59         :: 959805027;
    KBTS_FEATURE_TAG_cv60         :: 808875619;
    KBTS_FEATURE_TAG_cv61         :: 825652835;
    KBTS_FEATURE_TAG_cv62         :: 842430051;
    KBTS_FEATURE_TAG_cv63         :: 859207267;
    KBTS_FEATURE_TAG_cv64         :: 875984483;
    KBTS_FEATURE_TAG_cv65         :: 892761699;
    KBTS_FEATURE_TAG_cv66         :: 909538915;
    KBTS_FEATURE_TAG_cv67         :: 926316131;
    KBTS_FEATURE_TAG_cv68         :: 943093347;
    KBTS_FEATURE_TAG_cv69         :: 959870563;
    KBTS_FEATURE_TAG_cv70         :: 808941155;
    KBTS_FEATURE_TAG_cv71         :: 825718371;
    KBTS_FEATURE_TAG_cv72         :: 842495587;
    KBTS_FEATURE_TAG_cv73         :: 859272803;
    KBTS_FEATURE_TAG_cv74         :: 876050019;
    KBTS_FEATURE_TAG_cv75         :: 892827235;
    KBTS_FEATURE_TAG_cv76         :: 909604451;
    KBTS_FEATURE_TAG_cv77         :: 926381667;
    KBTS_FEATURE_TAG_cv78         :: 943158883;
    KBTS_FEATURE_TAG_cv79         :: 959936099;
    KBTS_FEATURE_TAG_cv80         :: 809006691;
    KBTS_FEATURE_TAG_cv81         :: 825783907;
    KBTS_FEATURE_TAG_cv82         :: 842561123;
    KBTS_FEATURE_TAG_cv83         :: 859338339;
    KBTS_FEATURE_TAG_cv84         :: 876115555;
    KBTS_FEATURE_TAG_cv85         :: 892892771;
    KBTS_FEATURE_TAG_cv86         :: 909669987;
    KBTS_FEATURE_TAG_cv87         :: 926447203;
    KBTS_FEATURE_TAG_cv88         :: 943224419;
    KBTS_FEATURE_TAG_cv89         :: 960001635;
    KBTS_FEATURE_TAG_cv90         :: 809072227;
    KBTS_FEATURE_TAG_cv91         :: 825849443;
    KBTS_FEATURE_TAG_cv92         :: 842626659;
    KBTS_FEATURE_TAG_cv93         :: 859403875;
    KBTS_FEATURE_TAG_cv94         :: 876181091;
    KBTS_FEATURE_TAG_cv95         :: 892958307;
    KBTS_FEATURE_TAG_cv96         :: 909735523;
    KBTS_FEATURE_TAG_cv97         :: 926512739;
    KBTS_FEATURE_TAG_cv98         :: 943289955;
    KBTS_FEATURE_TAG_cv99         :: 960067171;
    KBTS_FEATURE_TAG_c2pc         :: 1668297315;
    KBTS_FEATURE_TAG_c2sc         :: 1668493923;
    KBTS_FEATURE_TAG_dist         :: 1953720676;
    KBTS_FEATURE_TAG_dlig         :: 1734962276;
    KBTS_FEATURE_TAG_dtls         :: 1936487524;
    KBTS_FEATURE_TAG_expt         :: 1953527909;
    KBTS_FEATURE_TAG_falt         :: 1953259878;
    KBTS_FEATURE_TAG_flac         :: 1667329126;
    KBTS_FEATURE_TAG_fwid         :: 1684633446;
    KBTS_FEATURE_TAG_haln         :: 1852596584;
    KBTS_FEATURE_TAG_halt         :: 1953259880;
    KBTS_FEATURE_TAG_hist         :: 1953720680;
    KBTS_FEATURE_TAG_hkna         :: 1634626408;
    KBTS_FEATURE_TAG_hlig         :: 1734962280;
    KBTS_FEATURE_TAG_hngl         :: 1818717800;
    KBTS_FEATURE_TAG_hojo         :: 1869246312;
    KBTS_FEATURE_TAG_hwid         :: 1684633448;
    KBTS_FEATURE_TAG_ital         :: 1818326121;
    KBTS_FEATURE_TAG_jalt         :: 1953259882;
    KBTS_FEATURE_TAG_jp78         :: 943157354;
    KBTS_FEATURE_TAG_jp83         :: 859336810;
    KBTS_FEATURE_TAG_jp90         :: 809070698;
    KBTS_FEATURE_TAG_jp04         :: 875589738;
    KBTS_FEATURE_TAG_kern         :: 1852990827;
    KBTS_FEATURE_TAG_lfbd         :: 1684170348;
    KBTS_FEATURE_TAG_liga         :: 1634167148;
    KBTS_FEATURE_TAG_lnum         :: 1836412524;
    KBTS_FEATURE_TAG_locl         :: 1818455916;
    KBTS_FEATURE_TAG_ltra         :: 1634890860;
    KBTS_FEATURE_TAG_ltrm         :: 1836217452;
    KBTS_FEATURE_TAG_mark         :: 1802658157;
    KBTS_FEATURE_TAG_mgrk         :: 1802659693;
    KBTS_FEATURE_TAG_mkmk         :: 1802333037;
    KBTS_FEATURE_TAG_mset         :: 1952805741;
    KBTS_FEATURE_TAG_nalt         :: 1953259886;
    KBTS_FEATURE_TAG_nlck         :: 1801677934;
    KBTS_FEATURE_TAG_nukt         :: 1953199470;
    KBTS_FEATURE_TAG_onum         :: 1836412527;
    KBTS_FEATURE_TAG_opbd         :: 1684172911;
    KBTS_FEATURE_TAG_ordn         :: 1852076655;
    KBTS_FEATURE_TAG_ornm         :: 1835954799;
    KBTS_FEATURE_TAG_palt         :: 1953259888;
    KBTS_FEATURE_TAG_pcap         :: 1885430640;
    KBTS_FEATURE_TAG_pkna         :: 1634626416;
    KBTS_FEATURE_TAG_pnum         :: 1836412528;
    KBTS_FEATURE_TAG_pres         :: 1936028272;
    KBTS_FEATURE_TAG_psts         :: 1937011568;
    KBTS_FEATURE_TAG_pwid         :: 1684633456;
    KBTS_FEATURE_TAG_qwid         :: 1684633457;
    KBTS_FEATURE_TAG_rand         :: 1684955506;
    KBTS_FEATURE_TAG_rclt         :: 1953260402;
    KBTS_FEATURE_TAG_rkrf         :: 1718774642;
    KBTS_FEATURE_TAG_rlig         :: 1734962290;
    KBTS_FEATURE_TAG_rtbd         :: 1684173938;
    KBTS_FEATURE_TAG_rtla         :: 1634497650;
    KBTS_FEATURE_TAG_rtlm         :: 1835824242;
    KBTS_FEATURE_TAG_ruby         :: 2036495730;
    KBTS_FEATURE_TAG_rvrn         :: 1852995186;
    KBTS_FEATURE_TAG_salt         :: 1953259891;
    KBTS_FEATURE_TAG_sinf         :: 1718511987;
    KBTS_FEATURE_TAG_size         :: 1702521203;
    KBTS_FEATURE_TAG_smcp         :: 1885564275;
    KBTS_FEATURE_TAG_smpl         :: 1819307379;
    KBTS_FEATURE_TAG_ss01         :: 825258867;
    KBTS_FEATURE_TAG_ss02         :: 842036083;
    KBTS_FEATURE_TAG_ss03         :: 858813299;
    KBTS_FEATURE_TAG_ss04         :: 875590515;
    KBTS_FEATURE_TAG_ss05         :: 892367731;
    KBTS_FEATURE_TAG_ss06         :: 909144947;
    KBTS_FEATURE_TAG_ss07         :: 925922163;
    KBTS_FEATURE_TAG_ss08         :: 942699379;
    KBTS_FEATURE_TAG_ss09         :: 959476595;
    KBTS_FEATURE_TAG_ss10         :: 808547187;
    KBTS_FEATURE_TAG_ss11         :: 825324403;
    KBTS_FEATURE_TAG_ss12         :: 842101619;
    KBTS_FEATURE_TAG_ss13         :: 858878835;
    KBTS_FEATURE_TAG_ss14         :: 875656051;
    KBTS_FEATURE_TAG_ss15         :: 892433267;
    KBTS_FEATURE_TAG_ss16         :: 909210483;
    KBTS_FEATURE_TAG_ss17         :: 925987699;
    KBTS_FEATURE_TAG_ss18         :: 942764915;
    KBTS_FEATURE_TAG_ss19         :: 959542131;
    KBTS_FEATURE_TAG_ss20         :: 808612723;
    KBTS_FEATURE_TAG_ssty         :: 2037674867;
    KBTS_FEATURE_TAG_stch         :: 1751348339;
    KBTS_FEATURE_TAG_subs         :: 1935832435;
    KBTS_FEATURE_TAG_sups         :: 1936749939;
    KBTS_FEATURE_TAG_swsh         :: 1752397683;
    KBTS_FEATURE_TAG_test         :: 1953719668;
    KBTS_FEATURE_TAG_titl         :: 1819568500;
    KBTS_FEATURE_TAG_tnam         :: 1835101812;
    KBTS_FEATURE_TAG_tnum         :: 1836412532;
    KBTS_FEATURE_TAG_trad         :: 1684107892;
    KBTS_FEATURE_TAG_twid         :: 1684633460;
    KBTS_FEATURE_TAG_unic         :: 1667853941;
    KBTS_FEATURE_TAG_valt         :: 1953259894;
    KBTS_FEATURE_TAG_vapk         :: 1802527094;
    KBTS_FEATURE_TAG_vatu         :: 1970561398;
    KBTS_FEATURE_TAG_vchw         :: 2003329910;
    KBTS_FEATURE_TAG_vert         :: 1953654134;
    KBTS_FEATURE_TAG_vhal         :: 1818323062;
    KBTS_FEATURE_TAG_vkna         :: 1634626422;
    KBTS_FEATURE_TAG_vkrn         :: 1852992374;
    KBTS_FEATURE_TAG_vpal         :: 1818325110;
    KBTS_FEATURE_TAG_vrt2         :: 846492278;
    KBTS_FEATURE_TAG_vrtr         :: 1920234102;
    KBTS_FEATURE_TAG_zero         :: 1869768058;
}

kbts__gdef :: struct {}
kbts__cmap_14 :: struct {}
kbts__gsub_gpos :: struct {}
kbts__maxp :: struct {}
kbts__hea :: struct {}
kbts_shaper_properties :: struct {}
kbts__feature :: struct {}
kbts__head :: struct {}
kbts__langsys :: struct {}
kbts_shape_config :: struct {}

kbts_glyph_config :: struct {}
kbts_shape_context :: struct {}

kbts_shape_scratchpad :: struct {}

kbts_allocator_op_allocate :: struct {
    Pointer: *void;
    Size:    u32;
}

kbts_allocator_op_free :: struct {
    Pointer: *void;
}

kbts_allocator_op :: struct {
    Kind: kbts_allocator_op_kind;

    struct {
        Allocate: kbts_allocator_op_allocate;

        #overlay (Allocate) Free: kbts_allocator_op_free;
    }
}

kbts_allocator_function :: #type (Data: *void, Op: *kbts_allocator_op) -> void #c_call;

kbts_blob_table :: struct {
    OffsetFromStartOfFile: u32;
    Length:                u32;
}

kbts_load_font_state :: struct {
    FontData:                             *void;
    FontDataSize:                         u32;

    Tables:                               [18] kbts_blob_table;
    LookupCount:                          u32;
    LookupSubtableCount:                  u32;
    GlyphCount:                           u32;
    ScratchSize:                          u32;

    GlyphLookupMatrixSizeInBytes:         u32;
    GlyphLookupSubtableMatrixSizeInBytes: u32;
    TotalSize:                            u32;
}

kbts_blob_header :: struct {
    Magic:                                           u32;
    Version:                                         u32;

    LookupCount:                                     u32;
    LookupSubtableCount:                             u32;
    GlyphCount:                                      u32;

    GposLookupIndexOffset:                           u32;

    GlyphLookupMatrixOffsetFromStartOfFile:          u32;
    GlyphLookupSubtableMatrixOffsetFromStartOfFile:  u32;
    LookupSubtableIndexOffsetsOffsetFromStartOfFile: u32;
    SubtableInfosOffsetFromStartOfFile:              u32;

    Tables:                                          [18] kbts_blob_table;
}

kbts_font :: struct {
    Allocator:     kbts_allocator_function;
    AllocatorData: *void;

    Blob:          *kbts_blob_header;
    Cmap:          *u16;
    Cmap14:        *kbts__cmap_14;

    ShapingTables: [2] *kbts__gsub_gpos;

    UserData:      *void;

    Error:         kbts_load_font_error;
}

kbts_font_info :: struct {
    Strings:       [13] *u8;
    StringLengths: [13] u16;

    StyleFlags:    kbts_font_style_flags;
    Weight:        kbts_font_weight;
    Width:         kbts_font_width;
}

kbts_font_info2 :: struct {
    Size:          u32;

    Strings:       [13] *u8;
    StringLengths: [13] u16;

    StyleFlags:    kbts_font_style_flags;
    Weight:        kbts_font_weight;
    Width:         kbts_font_width;
}

kbts_font_info2_1 :: struct {
    Base:       kbts_font_info2;

    UnitsPerEm: u16;

    XMin:       s16;
    YMin:       s16;
    XMax:       s16;
    YMax:       s16;

    Ascent:     s16;
    Descent:    s16;
    LineGap:    s16;
}

kbts_font_info2_2 :: struct {
    Base:          kbts_font_info2;

    // _1
    UnitsPerEm:    u16;

    XMin:          s16;
    YMin:          s16;
    XMax:          s16;
    YMax:          s16;

    Ascent:        s16;
    Descent:       s16;
    LineGap:       s16;

    // For now, this is just OS2.sCapHeight.
    // If/when this is zero, we might consider trying to communicate a useful height instead of simply passing the zero along.
    CapitalHeight: s16;
}

kbts_feature_override :: struct {
    Tag:   kbts_feature_tag;
    Value: s32;
}

kbts_variation :: struct {
    Tag:   u32;
    Value: float;
}

kbts_break :: struct {
    // The break code mostly works in relative positions, but we convert to absolute positions for the user.
    // That way, breaks can be trivially stored and compared and such and it just works.
    Position:           s32;
    Flags:              kbts_break_flags;
    Direction:          kbts_direction; // Only valid if (Flags & KBTS_BREAK_FLAG_DIRECTION).
    ParagraphDirection: kbts_direction; // Only valid if (Flags & KBTS_BREAK_FLAG_PARAGRAPH_DIRECTION).
    Script:             kbts_script; // Only valid if (Flags & KBTS_BREAK_FLAG_SCRIPT).
}

kbts_bracket :: struct {
    Codepoint: u32;
    Position:  u32;
    Direction: u8;
    Script:    u8;
}

// In the worst case, a single call to BreakAddCodepoint would generate 4 breaks.
// We buffer breaks to reorder them before returning them to the user.
// This potentially requires infinite memory, which we don't have, so you may want to tweak this constant,
// although, really, if the defaults don't work, then you have likely found very strange/adversarial text.
kbts_break_state :: struct {
    Breaks:                             [8] kbts_break;
    BreakCount:                         u32;

    ParagraphDirection:                 kbts_direction;
    UserParagraphDirection:             kbts_direction;

    CurrentPosition:                    u32;
    ParagraphStartPosition:             u32;

    LastScriptBreakPosition:            u32;
    LastDirectionBreakPosition:         u32;
    LastScriptBreakScript:              u8;
    LastDirectionBreakDirection:        u8;

    ScriptPositionOffset:               s16;
    ScriptCount:                        u32;
    ScriptSet:                          [23] u8;

    Brackets:                           [64] kbts_bracket;
    BracketCount:                       u32;
    Flags:                              kbts_break_state_flags;

    FlagState:                          u32; // u8(kbts_break_flags)x4
    PositionOffset2:                    s16;
    PositionOffset3:                    s16;

    WordBreakHistory:                   u32; // u8x4
    WordBreaks:                         u16; // u4x4
    WordUnbreaks:                       u16; // u4x4
    WordBreak2PositionOffset:           s16;

    LineBreaks:                         u64; // u16x4

    LineUnbreaksAsync:                  u64; // u16x4
    LineUnbreaks:                       u64; // u16x4
    LineBreakHistory:                   u32; // u8(line_break_class)x4
    LineBreak2PositionOffset:           s16;
    LineBreak3PositionOffset:           s16;

    LastDirection:                      u8;
    BidirectionalClass2:                u8;
    BidirectionalClass1:                u8;
    Bidirectional1PositionOffset:       s16;
    Bidirectional2PositionOffset:       s16; // Unused

    JapaneseLineBreakStyle:             kbts_japanese_line_break_style;
    ConfigFlags:                        kbts_break_config_flags;
    GraphemeBreakState:                 u8;
    LastLineBreakClass:                 u8;
    LastWordBreakClass:                 u8;
    LastWordBreakClassIncludingIgnored: u8;
}

kbts_decode :: struct {
    Codepoint:                s32;

    SourceCharactersConsumed: s32;
    Valid:                    s32;
}

kbts_encode_utf8 :: struct {
    Encoded:       [4] u8;
    EncodedLength: s32;
    Valid:         s32;
}

kbts_glyph_classes :: struct {
    Class:               u16;
    MarkAttachmentClass: u16;
}

kbts__bucketed_glyph :: struct {}
kbts_glyph :: struct {
    Prev:                          *kbts_glyph;
    Next:                          *kbts_glyph;

    Codepoint:                     u32;
    Id:                            u16; // Glyph index. This is what you want to use to query outline data.
    Uid:                           u16;

    // This field is kept and returned as-is throughout the shaping process.
    // When you are using the context API, it contains a codepoint index always!
    // To get the original user ID with the context API, you need to get the corresponding kbts_shape_codepoint
    // with kbts_ShapeGetShapeCodepoint(Context, Glyph->UserIdOrCodepointIndex, ...);
    UserIdOrCodepointIndex:        s32;

    // Used by GPOS
    OffsetX:                       s32;
    OffsetY:                       s32;
    AdvanceX:                      s32;
    AdvanceY:                      s32;

    AttachGlyph:                   *kbts_glyph; // Set by GPOS attachments.

    Config:                        *kbts_glyph_config;

    // @Memory: We definitely don't need to carry this around for the entire shaping process.
    Decomposition:                 u64;

    Classes:                       kbts_glyph_classes;

    Flags:                         kbts_glyph_flags;

    ParentInfo:                    u32;

    Bucketed:                      *kbts__bucketed_glyph;
    SortKey:                       u32;
    SortKeyInterval:               u32;
    BucketedBucketIndex:           u16;

    // This is set by GSUB and used by GPOS.
    // A 0-index means that we should attach to the last component in the ligature.
    //
    // From the Microsoft docs:
    //   To correctly access the subtables, the client must keep track of the component associated with the mark.
    //
    //   For a given mark assigned to a particular class, the appropriate base attachment point is determined by which
    //   ligature component the mark is associated with. This is dependent on the original character string and subsequent
    //   character- or glyph-sequence processing, not the font data alone. While a text-layout client is performing any
    //   character-based preprocessing or any glyph-substitution operations using the GSUB table, the text-layout client
    //   must keep track of associations of marks to particular ligature-glyph components.
    LigatureUid:                   u16;
    LigatureComponentIndexPlusOne: u16;
    LigatureComponentCount:        u16;

    // Set in GSUB and used in GPOS, for STCH.
    JoiningFeature:                kbts_joining_feature;

    // Unicode properties filled in by CodepointToGlyph.
    JoiningType:                   kbts_unicode_joining_type;
    UnicodeFlags:                  u8;
    SyllabicClass:                 u8;
    SyllabicPosition:              u8;
    UseClass:                      u8;
    CombiningClass:                u8;

    MarkOrdering:                  u8; // Only used temporarily in NORMALIZE for Arabic mark reordering.
}

kbts_shape_codepoint :: struct {
    Font:                 *kbts_font; // Only set when (BreakFlags & KBTS_BREAK_FLAG_GRAPHEME) != 0.

    FeatureOverrides:     *kbts_feature_override;
    FeatureOverrideCount: s32;

    Codepoint:            s32;
    UserId:               s32;

    BreakFlags:           kbts_break_flags;
    Script:               kbts_script; // Only set when (BreakFlags & KBTS_BREAK_FLAG_SCRIPT) != 0.
    Direction:            kbts_direction; // Only set when (BreakFlags & KBTS_BREAK_FLAG_DIRECTION) != 0.
    ParagraphDirection:   kbts_direction; // Only set when (BreakFlags & KBTS_BREAK_FLAG_PARAGRAPH_DIRECTION) != 0.
}

kbts_shape_codepoint2 :: struct {
    Size:                 s32;
    Padding0:             s32;

    Font:                 *kbts_font; // Only set when (BreakFlags & KBTS_BREAK_FLAG_GRAPHEME) != 0.
    VariationVector:      *float; // Only set when (BreakFlags & KBTS_BREAK_FLAG_GRAPHEME) != 0.

    FeatureOverrides:     *kbts_feature_override;
    FeatureOverrideCount: s32;

    Codepoint:            s32;
    UserId:               s32;

    BreakFlags:           kbts_break_flags;
    Script:               kbts_script; // Only set when (BreakFlags & KBTS_BREAK_FLAG_SCRIPT) != 0.
    Direction:            kbts_direction; // Only set when (BreakFlags & KBTS_BREAK_FLAG_DIRECTION) != 0.
    ParagraphDirection:   kbts_direction; // Only set when (BreakFlags & KBTS_BREAK_FLAG_PARAGRAPH_DIRECTION) != 0.
}

kbts__shape_codepoint :: struct {}
kbts_shape_codepoint_iterator :: struct {
    Codepoint:                  *kbts__shape_codepoint;
    Context:                    *kbts_shape_context;

    EndBlockIndex:              u32;
    OnePastLastCodepointIndex:  u32;
    BlockIndex:                 u32;
    CodepointIndex:             u32;
    CurrentBlockCodepointCount: u32;
    FlatCodepointIndex:         u32;
}

kbts_glyph_iterator :: struct {
    GlyphStorage: *kbts_glyph_storage;
    CurrentGlyph: *kbts_glyph;

    LastAdvanceX: s32;
    X:            s32;
    Y:            s32;
}

kbts_arena_block_header :: struct {
    Prev: *kbts_arena_block_header;
    Next: *kbts_arena_block_header;
}

kbts_arena :: struct {
    Allocator:         kbts_allocator_function;
    AllocatorData:     *void;

    BlockSentinel:     kbts_arena_block_header;
    FreeBlockSentinel: kbts_arena_block_header;

    Error:             s32;
}

kbts_glyph_storage :: struct {
    Arena:             kbts_arena;

    GlyphSentinel:     kbts_glyph;
    FreeGlyphSentinel: kbts_glyph;

    Error:             s32;
}

kbts_glyph_parent :: struct {
    Codepoint:  u32;
    Codepoint1: u32;
}

kbts_font_coverage_test :: struct {
    Font:             *kbts_font;
    BaseCodepoint:    u32;

    CurrentBaseError: s32;
    Error:            s32;

    BaseParents:      [19] kbts_glyph_parent;
    BaseParentCount:  u32;
}

kbts_run :: struct {
    Font:               *kbts_font;
    Script:             kbts_script;
    ParagraphDirection: kbts_direction;
    Direction:          kbts_direction;
    Flags:              kbts_break_flags;

    Glyphs:             kbts_glyph_iterator;
}

kbts_run2 :: struct {
    // kbts_run:
    Font:               *kbts_font;
    Script:             kbts_script;
    ParagraphDirection: kbts_direction;
    Direction:          kbts_direction;
    Flags:              kbts_break_flags;

    Glyphs:             kbts_glyph_iterator;

    // New fields:
    VariationVector:    *float;
}

kbts_uid :: struct {
    Data: [4] u32;
}

kbts_variation_axis_info :: struct {
    Tag:          u32;
    MinimumValue: float;
    DefaultValue: float;
    MaximumValue: float;
    Flags:        kbts_variation_axis_flags;
    NameStringId: u16;
}

kbts_variation_instance_info :: struct {
    SubfamilyNameStringId:  u16;
    PostscriptNameStringId: u16;
    Flags:                  kbts_variation_instance_flags;
}

//
// Context API
// The context can do everything for you. It is pretty convenient!
//
kbts_SizeOfShapeContext :: () -> s32 #foreign kb_text_shape;
kbts_PlaceShapeContext2 :: (Allocator: kbts_allocator_function, AllocatorData: *void, Memory: *void, Flags: kbts_shape_context_flags) -> *kbts_shape_context #foreign kb_text_shape;
kbts_PlaceShapeContext :: (Allocator: kbts_allocator_function, AllocatorData: *void, Memory: *void) -> *kbts_shape_context #foreign kb_text_shape;
kbts_PlaceShapeContextFixedMemory2 :: (Memory: *void, Size: s32, Flags: kbts_shape_context_flags) -> *kbts_shape_context #foreign kb_text_shape;
kbts_PlaceShapeContextFixedMemory :: (Memory: *void, Size: s32) -> *kbts_shape_context #foreign kb_text_shape;
kbts_CreateShapeContext2 :: (Allocator: kbts_allocator_function, AllocatorData: *void, Flags: kbts_shape_context_flags) -> *kbts_shape_context #foreign kb_text_shape;
kbts_CreateShapeContext :: (Allocator: kbts_allocator_function, AllocatorData: *void) -> *kbts_shape_context #foreign kb_text_shape;
kbts_DestroyShapeContext :: (Context: *kbts_shape_context) -> void #foreign kb_text_shape;

kbts_ShapePushFontFromFile2 :: (Context: *kbts_shape_context, FileName: *u8, FontIndex: s32, Variations: *kbts_variation, VariationCount: s32, ContextFontHandle: *u32) -> *kbts_font #foreign kb_text_shape;
kbts_ShapePushFontFromFile :: (Context: *kbts_shape_context, FileName: *u8, FontIndex: s32) -> *kbts_font #foreign kb_text_shape;

kbts_ShapePushFontFromMemory2 :: (Context: *kbts_shape_context, Memory: *void, Size: s32, FontIndex: s32, Variations: *kbts_variation, VariationCount: s32, ContextFontHandle: *u32) -> *kbts_font #foreign kb_text_shape;
kbts_ShapePushFontFromMemory :: (Context: *kbts_shape_context, Memory: *void, Size: s32, FontIndex: s32) -> *kbts_font #foreign kb_text_shape;
kbts_ShapePushFont2 :: (Context: *kbts_shape_context, Font: *kbts_font, Variations: *kbts_variation, VariationCount: s32, ContextFontHandle: *u32) -> *kbts_font #foreign kb_text_shape;
kbts_ShapePushFont :: (Context: *kbts_shape_context, Font: *kbts_font) -> *kbts_font #foreign kb_text_shape;
kbts_ShapePopFont :: (Context: *kbts_shape_context) -> *kbts_font #foreign kb_text_shape;
kbts_ShapeBegin :: (Context: *kbts_shape_context, ParagraphDirection: kbts_direction, Language: kbts_language) -> void #foreign kb_text_shape;
kbts_ShapeEnd :: (Context: *kbts_shape_context) -> void #foreign kb_text_shape;
kbts_ShapeRun :: (Context: *kbts_shape_context, Run: *kbts_run) -> s32 #foreign kb_text_shape;
kbts_ShapePushFeature :: (Context: *kbts_shape_context, FeatureTag: u32, Value: s32) -> void #foreign kb_text_shape;
kbts_ShapePopFeature :: (Context: *kbts_shape_context, FeatureTag: u32) -> s32 #foreign kb_text_shape;
kbts_ShapeCodepoint :: (Context: *kbts_shape_context, Codepoint: s32) -> void #foreign kb_text_shape;
kbts_ShapeCodepointWithUserId :: (Context: *kbts_shape_context, Codepoint: s32, UserId: s32) -> void #foreign kb_text_shape;
kbts_ShapeUtf32 :: (Context: *kbts_shape_context, Utf32: *s32, Length: s32) -> void #foreign kb_text_shape;
kbts_ShapeUtf32WithUserId :: (Context: *kbts_shape_context, Utf32: *s32, Length: s32, UserId: s32, UserIdIncrement: s32) -> void #foreign kb_text_shape;
kbts_ShapeUtf8 :: (Context: *kbts_shape_context, Utf8: *u8, Length: s32, UserIdGenerationMode: kbts_user_id_generation_mode) -> void #foreign kb_text_shape;
kbts_ShapeUtf8WithUserId :: (Context: *kbts_shape_context, Utf8: *u8, Length: s32, UserId: s32, UserIdGenerationMode: kbts_user_id_generation_mode) -> void #foreign kb_text_shape;
kbts_ShapeError :: (Context: *kbts_shape_context) -> kbts_shape_error #foreign kb_text_shape;
kbts_ShapeBeginManualRuns :: (Context: *kbts_shape_context) -> void #foreign kb_text_shape;
kbts_ShapeNextManualRun :: (Context: *kbts_shape_context, Direction: kbts_direction, Script: kbts_script) -> void #foreign kb_text_shape;
kbts_ShapeEndManualRuns :: (Context: *kbts_shape_context) -> void #foreign kb_text_shape;
kbts_ShapeManualBreak :: (Context: *kbts_shape_context) -> void #foreign kb_text_shape;
kbts_ShapeCurrentCodepointsIterator :: (Context: *kbts_shape_context) -> kbts_shape_codepoint_iterator #foreign kb_text_shape;
kbts_ShapeCodepointIteratorIsValid :: (It: *kbts_shape_codepoint_iterator) -> s32 #foreign kb_text_shape;
kbts_ShapeCodepointIteratorNext2 :: (It: *kbts_shape_codepoint_iterator, Codepoint: *kbts_shape_codepoint2, CodepointIndex: *s32) -> s32 #foreign kb_text_shape;
kbts_ShapeCodepointIteratorNext :: (It: *kbts_shape_codepoint_iterator, Codepoint: *kbts_shape_codepoint, CodepointIndex: *s32) -> s32 #foreign kb_text_shape;
kbts_ShapeGetShapeCodepoint2 :: (Context: *kbts_shape_context, CodepointIndex: s32, Codepoint: *kbts_shape_codepoint2) -> s32 #foreign kb_text_shape;
kbts_ShapeGetShapeCodepoint :: (Context: *kbts_shape_context, CodepointIndex: s32, Codepoint: *kbts_shape_codepoint) -> s32 #foreign kb_text_shape;
kbts_ShapeSetFontVariationVector :: (Context: *kbts_shape_context, ContextFontHandle: u32, VariationVector: *float) -> s32 #foreign kb_text_shape;
kbts_ShapeSetFontVariation :: (Context: *kbts_shape_context, ContextFontHandle: u32, Tag: u32, Value: float) -> s32 #foreign kb_text_shape;
kbts_ShapePushGlobalVariation :: (Context: *kbts_shape_context, Tag: u32, Value: float) -> s32 #foreign kb_text_shape;
kbts_ShapePopGlobalVariation :: (Context: *kbts_shape_context, Tag: u32) -> s32 #foreign kb_text_shape;

//
// Direct API
//
kbts_ShapeDirect2 :: (Scratchpad: *kbts_shape_scratchpad, Storage: *kbts_glyph_storage, RunDirection: kbts_direction, VariationVectorNormalized: *s16, Output: *kbts_glyph_iterator) -> kbts_shape_error #foreign kb_text_shape;
kbts_ShapeDirect :: (Scratchpad: *kbts_shape_scratchpad, Storage: *kbts_glyph_storage, RunDirection: kbts_direction, Output: *kbts_glyph_iterator) -> kbts_shape_error #foreign kb_text_shape;

kbts_FontFromFile :: (FileName: *u8, FontIndex: s32, Allocator: kbts_allocator_function, AllocatorData: *void, FileData: **void, FileSize: *s32) -> kbts_font #foreign kb_text_shape;

kbts_FontCount :: (FileData: *void, FileSize: s32) -> s32 #foreign kb_text_shape;
kbts_FontFromMemory :: (FileData: *void, FileSize: s32, FontIndex: s32, Allocator: kbts_allocator_function, AllocatorData: *void) -> kbts_font #foreign kb_text_shape;
kbts_FreeFont :: (Font: *kbts_font) -> void #foreign kb_text_shape;
kbts_FontIsValid :: (Font: *kbts_font) -> s32 #foreign kb_text_shape;
kbts_LoadFont :: (Font: *kbts_font, State: *kbts_load_font_state, FontData: *void, FontDataSize: s32, FontIndex: s32, ScratchSize_: *s32, OutputSize_: *s32) -> kbts_load_font_error #foreign kb_text_shape;
kbts_PlaceBlob :: (Font: *kbts_font, State: *kbts_load_font_state, ScratchMemory: *void, OutputMemory: *void) -> kbts_load_font_error #foreign kb_text_shape;

// Fetching font information
kbts_GetFontInfo2 :: (Font: *kbts_font, Info: *kbts_font_info2) -> void #foreign kb_text_shape;
kbts_GetFontInfo :: (Font: *kbts_font, Info: *kbts_font_info) -> void #foreign kb_text_shape;
kbts_GetVariationInfo :: (Font: *kbts_font, AxisCount: *s32, InstanceCount: *s32) -> void #foreign kb_text_shape;
kbts_NormalizeVariationVector :: (Font: *kbts_font, VariationVector: *float, VariationVectorNormalized: *s16) -> void #foreign kb_text_shape;
kbts_WindowsIdsForLanguage :: (Language: kbts_language, Ids: *kbts_windows_language_id, IdCapacity: s32) -> s32 #foreign kb_text_shape;
kbts_LookupFontString :: (Font: *kbts_font, StringId: kbts_font_info_string_id, LanguageId: kbts_windows_language_id, String: *u8, StringCapacity: s32) -> s32 #foreign kb_text_shape;

// A shape_config is a bag of pre-computed data for a specific shaping setup.
kbts_SizeOfShapeConfig2 :: (Font: *kbts_font, Script: kbts_script, Language: kbts_language, VariationVector: *float) -> s32 #foreign kb_text_shape;
kbts_SizeOfShapeConfig :: (Font: *kbts_font, Script: kbts_script, Language: kbts_language) -> s32 #foreign kb_text_shape;
kbts_PlaceShapeConfig2 :: (Font: *kbts_font, Script: kbts_script, Language: kbts_language, VariationVector: *float, Memory: *void, Uid: *kbts_uid) -> *kbts_shape_config #foreign kb_text_shape;
kbts_PlaceShapeConfig :: (Font: *kbts_font, Script: kbts_script, Language: kbts_language, Memory: *void) -> *kbts_shape_config #foreign kb_text_shape;
kbts_CreateShapeConfig2 :: (Font: *kbts_font, Script: kbts_script, Language: kbts_language, VariationVector: *float, Allocator: kbts_allocator_function, AllocatorData: *void, Uid: *kbts_uid) -> *kbts_shape_config #foreign kb_text_shape;
kbts_CreateShapeConfig :: (Font: *kbts_font, Script: kbts_script, Language: kbts_language, Allocator: kbts_allocator_function, AllocatorData: *void) -> *kbts_shape_config #foreign kb_text_shape;

kbts_DestroyShapeConfig :: (Config: *kbts_shape_config) -> void #foreign kb_text_shape;

// A glyph_storage holds and recycles glyph data.
kbts_InitializeGlyphStorage :: (Storage: *kbts_glyph_storage, Allocator: kbts_allocator_function, AllocatorData: *void) -> s32 #foreign kb_text_shape;
kbts_InitializeGlyphStorageFixedMemory :: (Storage: *kbts_glyph_storage, Memory: *void, MemorySize: s32) -> s32 #foreign kb_text_shape;
kbts_PushGlyph :: (Storage: *kbts_glyph_storage, Font: *kbts_font, Codepoint: s32, Config: *kbts_glyph_config, UserId: s32) -> *kbts_glyph #foreign kb_text_shape;
kbts_ClearActiveGlyphs :: (Storage: *kbts_glyph_storage) -> void #foreign kb_text_shape;
kbts_FreeAllGlyphs :: (Storage: *kbts_glyph_storage) -> void #foreign kb_text_shape;
kbts_CodepointToGlyph :: (Font: *kbts_font, Codepoint: s32, Config: *kbts_glyph_config, UserId: s32) -> kbts_glyph #foreign kb_text_shape;
kbts_CodepointToGlyphId :: (Font: *kbts_font, Codepoint: s32) -> s32 #foreign kb_text_shape;
kbts_ActiveGlyphIterator :: (Storage: *kbts_glyph_storage) -> kbts_glyph_iterator #foreign kb_text_shape;

// A glyph_config specifies glyph-specific shaping parameters.
// A single glyph_config can be shared by multiple glyphs.
kbts_SizeOfGlyphConfig :: (ShapeConfig: *kbts_shape_config, Overrides: *kbts_feature_override, OverrideCount: s32) -> s32 #foreign kb_text_shape;
kbts_PlaceGlyphConfig :: (ShapeConfig: *kbts_shape_config, Overrides: *kbts_feature_override, OverrideCount: s32, Memory: *void) -> *kbts_glyph_config #foreign kb_text_shape;
kbts_CreateGlyphConfig :: (ShapeConfig: *kbts_shape_config, Overrides: *kbts_feature_override, OverrideCount: s32, Allocator: kbts_allocator_function, AllocatorData: *void) -> *kbts_glyph_config #foreign kb_text_shape;
kbts_DestroyGlyphConfig :: (Config: *kbts_glyph_config) -> void #foreign kb_text_shape;

// A shape_scratchpad holds all transient runtime shaping data.
// While the shape_config is immutable and can be trivially shared among threads, a
// shape_scratchpad is mutable and needs to be per-thread.
kbts_SizeOfShapeScratchpad :: (Config: *kbts_shape_config) -> u64 #foreign kb_text_shape;
kbts_PlaceShapeScratchpad :: (Config: *kbts_shape_config, Memory: *void, Allocator: kbts_allocator_function, AllocatorData: *void) -> *kbts_shape_scratchpad #foreign kb_text_shape;
kbts_PlaceShapeScratchpadFixedMemory :: (Config: *kbts_shape_config, Memory: *void, Size: s32) -> *kbts_shape_scratchpad #foreign kb_text_shape;
kbts_CreateShapeScratchpad :: (Config: *kbts_shape_config, Allocator: kbts_allocator_function, AllocatorData: *void) -> *kbts_shape_scratchpad #foreign kb_text_shape;
kbts_DestroyShapeScratchpad :: (Scratchpad: *kbts_shape_scratchpad) -> void #foreign kb_text_shape;

//
// Glyph iterator
//
kbts_GlyphIteratorNext :: (It: *kbts_glyph_iterator, Glyph: **kbts_glyph) -> s32 #foreign kb_text_shape;
kbts_GlyphIteratorIsValid :: (It: *kbts_glyph_iterator) -> s32 #foreign kb_text_shape;

// This is a quick guess that stops at the first glyph that has a strong script/direction associated to it.
// It is convenient, but only works if you are sure your input text is mono-script and mono-direction.
kbts_GuessTextProperties :: (Text: *void, TextSizeInBytes: s32, Format: kbts_text_format, Direction: *kbts_direction, Script: *kbts_script) -> void #foreign kb_text_shape;
kbts_GuessTextPropertiesUtf32 :: (Utf32: *s32, Utf32Count: s32, Direction: *kbts_direction, Script: *kbts_script) -> void #foreign kb_text_shape;
kbts_GuessTextPropertiesUtf8 :: (Utf8: *u8, Utf8Length: s32, Direction: *kbts_direction, Script: *kbts_script) -> void #foreign kb_text_shape;

kbts_BreakBegin :: (State: *kbts_break_state, ParagraphDirection: kbts_direction, JapaneseLineBreakStyle: kbts_japanese_line_break_style, ConfigFlags: kbts_break_config_flags) -> void #foreign kb_text_shape;
kbts_BreakAddCodepoint :: (State: *kbts_break_state, Codepoint: s32, PositionIncrement: s32, EndOfText: s32) -> void #foreign kb_text_shape;
kbts_BreakEnd :: (State: *kbts_break_state) -> void #foreign kb_text_shape;
kbts_Break :: (State: *kbts_break_state, Break: *kbts_break) -> s32 #foreign kb_text_shape;
kbts_BreakEntireString :: (Direction: kbts_direction, JapaneseLineBreakStyle: kbts_japanese_line_break_style, ConfigFlags: kbts_break_config_flags, Input: *void, InputSizeInBytes: s32, InputFormat: kbts_text_format, Breaks: *kbts_break, BreakCapacity: s32, BreakCount: *s32, BreakFlags: *kbts_break_flags, BreakFlagCapacity: s32, BreakFlagCount: *s32) -> void #foreign kb_text_shape;
kbts_BreakEntireStringUtf32 :: (Direction: kbts_direction, JapaneseLineBreakStyle: kbts_japanese_line_break_style, ConfigFlags: kbts_break_config_flags, Utf32: *s32, Utf32Count: s32, Breaks: *kbts_break, BreakCapacity: s32, BreakCount: *s32, BreakFlags: *kbts_break_flags, BreakFlagCapacity: s32, BreakFlagCount: *s32) -> void #foreign kb_text_shape;
kbts_BreakEntireStringUtf8 :: (Direction: kbts_direction, JapaneseLineBreakStyle: kbts_japanese_line_break_style, ConfigFlags: kbts_break_config_flags, Utf8: *u8, Utf8Length: s32, Breaks: *kbts_break, BreakCapacity: s32, BreakCount: *s32, BreakFlags: *kbts_break_flags, BreakFlagCapacity: s32, BreakFlagCount: *s32) -> void #foreign kb_text_shape;

// Quick test for font support of a sequence of codepoints.
kbts_FontCoverageTestBegin :: (Test: *kbts_font_coverage_test, Font: *kbts_font) -> void #foreign kb_text_shape;
kbts_FontCoverageTestCodepoint :: (Test: *kbts_font_coverage_test, Codepoint: s32) -> void #foreign kb_text_shape;
kbts_FontCoverageTestEnd :: (Test: *kbts_font_coverage_test) -> s32 #foreign kb_text_shape;

kbts_DecodeUtf8 :: (Utf8: *u8, Length: u64) -> kbts_decode #foreign kb_text_shape;
kbts_DecodeUtf16 :: (Utf16: *u16, Length: u64, Flags: kbts_decode_utf16_flags) -> kbts_decode #foreign kb_text_shape;
kbts_EncodeUtf8 :: (Codepoint: s32) -> kbts_encode_utf8 #foreign kb_text_shape;
kbts_ScriptDirection :: (Script: kbts_script) -> kbts_direction #foreign kb_text_shape;
kbts_ScriptIsComplex :: (Script: kbts_script) -> s32 #foreign kb_text_shape;
kbts_ScriptTagToScript :: (Tag: kbts_script_tag) -> kbts_script #foreign kb_text_shape;

#scope_file


kb_text_shape :: #library,no_dll "vendor/kb_text_shape";

#scope_export
//
// This file was auto-generated using the following command:
//
// jai build.jai
//



FT_RENDER_POOL_SIZE :: 16384;

FT_MAX_MODULES :: 32;

TT_CONFIG_OPTION_MAX_RUNNABLE_OPCODES :: 1000000;

T1_MAX_DICT_DEPTH :: 5;

T1_MAX_SUBRS_CALLS :: 16;

T1_MAX_CHARSTRINGS_OPERANDS :: 256;

CFF_CONFIG_OPTION_DARKENING_PARAMETER_X1 :: 500;
CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y1 :: 400;

CFF_CONFIG_OPTION_DARKENING_PARAMETER_X2 :: 1000;
CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y2 :: 275;

CFF_CONFIG_OPTION_DARKENING_PARAMETER_X3 :: 1667;
CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y3 :: 275;

CFF_CONFIG_OPTION_DARKENING_PARAMETER_X4 :: 2333;
CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y4 :: 0;

FT_INT64_ZERO :: 0;

FT_OUTLINE_NONE :: 0x0;
FT_OUTLINE_OWNER :: 0x1;
FT_OUTLINE_EVEN_ODD_FILL :: 0x2;
FT_OUTLINE_REVERSE_FILL :: 0x4;
FT_OUTLINE_IGNORE_DROPOUTS :: 0x8;
FT_OUTLINE_SMART_DROPOUTS :: 0x10;
FT_OUTLINE_INCLUDE_STUBS :: 0x20;
FT_OUTLINE_OVERLAP :: 0x40;

FT_OUTLINE_HIGH_PRECISION :: 0x100;
FT_OUTLINE_SINGLE_PASS :: 0x200;

ft_outline_none :: FT_OUTLINE_NONE;
ft_outline_owner :: FT_OUTLINE_OWNER;
ft_outline_even_odd_fill :: FT_OUTLINE_EVEN_ODD_FILL;
ft_outline_reverse_fill :: FT_OUTLINE_REVERSE_FILL;
ft_outline_ignore_dropouts :: FT_OUTLINE_IGNORE_DROPOUTS;
ft_outline_high_precision :: FT_OUTLINE_HIGH_PRECISION;
ft_outline_single_pass :: FT_OUTLINE_SINGLE_PASS;

FT_CURVE_TAG_ON :: 0x01;
FT_CURVE_TAG_CONIC :: 0x00;
FT_CURVE_TAG_CUBIC :: 0x02;

FT_CURVE_TAG_HAS_SCANMODE :: 0x04;

FT_CURVE_TAG_TOUCH_X :: 0x08;
FT_CURVE_TAG_TOUCH_Y :: 0x10;

FT_CURVE_TAG_TOUCH_BOTH :: FT_CURVE_TAG_TOUCH_X | FT_CURVE_TAG_TOUCH_Y;

FT_Curve_Tag_On :: FT_CURVE_TAG_ON;
FT_Curve_Tag_Conic :: FT_CURVE_TAG_CONIC;
FT_Curve_Tag_Cubic :: FT_CURVE_TAG_CUBIC;
FT_Curve_Tag_Touch_X :: FT_CURVE_TAG_TOUCH_X;
FT_Curve_Tag_Touch_Y :: FT_CURVE_TAG_TOUCH_Y;

FT_Outline_MoveTo_Func :: FT_Outline_MoveToFunc;

FT_Outline_LineTo_Func :: FT_Outline_LineToFunc;

FT_Outline_ConicTo_Func :: FT_Outline_ConicToFunc;

FT_Outline_CubicTo_Func :: FT_Outline_CubicToFunc;

FT_Raster_Span_Func :: FT_SpanFunc;

FT_RASTER_FLAG_DEFAULT :: 0x0;
FT_RASTER_FLAG_AA :: 0x1;
FT_RASTER_FLAG_DIRECT :: 0x2;
FT_RASTER_FLAG_CLIP :: 0x4;
FT_RASTER_FLAG_SDF :: 0x8;

ft_raster_flag_default :: FT_RASTER_FLAG_DEFAULT;
ft_raster_flag_aa :: FT_RASTER_FLAG_AA;
ft_raster_flag_direct :: FT_RASTER_FLAG_DIRECT;
ft_raster_flag_clip :: FT_RASTER_FLAG_CLIP;

FT_Raster_New_Func :: FT_Raster_NewFunc;

FT_Raster_Done_Func :: FT_Raster_DoneFunc;

FT_Raster_Reset_Func :: FT_Raster_ResetFunc;

FT_Raster_Set_Mode_Func :: FT_Raster_SetModeFunc;

FT_Raster_Render_Func :: FT_Raster_RenderFunc;

FT_ERR_BASE :: 0;

FT_FACE_FLAG_SCALABLE :: 1 << 0;
FT_FACE_FLAG_FIXED_SIZES :: 1 << 1;
FT_FACE_FLAG_FIXED_WIDTH :: 1 << 2;
FT_FACE_FLAG_SFNT :: 1 << 3;
FT_FACE_FLAG_HORIZONTAL :: 1 << 4;
FT_FACE_FLAG_VERTICAL :: 1 << 5;
FT_FACE_FLAG_KERNING :: 1 << 6;
FT_FACE_FLAG_FAST_GLYPHS :: 1 << 7;
FT_FACE_FLAG_MULTIPLE_MASTERS :: 1 << 8;
FT_FACE_FLAG_GLYPH_NAMES :: 1 << 9;
FT_FACE_FLAG_EXTERNAL_STREAM :: 1 << 10;
FT_FACE_FLAG_HINTER :: 1 << 11;
FT_FACE_FLAG_CID_KEYED :: 1 << 12;
FT_FACE_FLAG_TRICKY :: 1 << 13;
FT_FACE_FLAG_COLOR :: 1 << 14;
FT_FACE_FLAG_VARIATION :: 1 << 15;
FT_FACE_FLAG_SVG :: 1 << 16;
FT_FACE_FLAG_SBIX :: 1 << 17;
FT_FACE_FLAG_SBIX_OVERLAY :: 1 << 18;

FT_STYLE_FLAG_ITALIC :: 1 << 0;
FT_STYLE_FLAG_BOLD :: 1 << 1;

FT_OPEN_MEMORY :: 0x1;
FT_OPEN_STREAM :: 0x2;
FT_OPEN_PATHNAME :: 0x4;
FT_OPEN_DRIVER :: 0x8;
FT_OPEN_PARAMS :: 0x10;

ft_open_memory :: FT_OPEN_MEMORY;
ft_open_stream :: FT_OPEN_STREAM;
ft_open_pathname :: FT_OPEN_PATHNAME;
ft_open_driver :: FT_OPEN_DRIVER;
ft_open_params :: FT_OPEN_PARAMS;

FT_LOAD_DEFAULT :: 0x0;
FT_LOAD_NO_SCALE :: 1 << 0;
FT_LOAD_NO_HINTING :: 1 << 1;
FT_LOAD_RENDER :: 1 << 2;
FT_LOAD_NO_BITMAP :: 1 << 3;
FT_LOAD_VERTICAL_LAYOUT :: 1 << 4;
FT_LOAD_FORCE_AUTOHINT :: 1 << 5;
FT_LOAD_CROP_BITMAP :: 1 << 6;
FT_LOAD_PEDANTIC :: 1 << 7;
FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH :: 1 << 9;
FT_LOAD_NO_RECURSE :: 1 << 10;
FT_LOAD_IGNORE_TRANSFORM :: 1 << 11;
FT_LOAD_MONOCHROME :: 1 << 12;
FT_LOAD_LINEAR_DESIGN :: 1 << 13;
FT_LOAD_SBITS_ONLY :: 1 << 14;
FT_LOAD_NO_AUTOHINT :: 1 << 15;

FT_LOAD_COLOR :: 1 << 20;
FT_LOAD_COMPUTE_METRICS :: 1 << 21;
FT_LOAD_BITMAP_METRICS_ONLY :: 1 << 22;
FT_LOAD_NO_SVG :: 1 << 24;

FT_LOAD_ADVANCE_ONLY :: 1 << 8;
FT_LOAD_SVG_ONLY :: 1 << 23;

FT_SUBGLYPH_FLAG_ARGS_ARE_WORDS :: 1;
FT_SUBGLYPH_FLAG_ARGS_ARE_XY_VALUES :: 2;
FT_SUBGLYPH_FLAG_ROUND_XY_TO_GRID :: 4;
FT_SUBGLYPH_FLAG_SCALE :: 8;
FT_SUBGLYPH_FLAG_XY_SCALE :: 0x40;
FT_SUBGLYPH_FLAG_2X2 :: 0x80;
FT_SUBGLYPH_FLAG_USE_MY_METRICS :: 0x200;

FT_FSTYPE_INSTALLABLE_EMBEDDING :: 0x0000;
FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING :: 0x0002;
FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING :: 0x0004;
FT_FSTYPE_EDITABLE_EMBEDDING :: 0x0008;
FT_FSTYPE_NO_SUBSETTING :: 0x0100;
FT_FSTYPE_BITMAP_EMBEDDING_ONLY :: 0x0200;

FREETYPE_MAJOR :: 2;
FREETYPE_MINOR :: 14;
FREETYPE_PATCH :: 3;

T1_MAX_MM_AXIS :: 4;
T1_MAX_MM_DESIGNS :: 16;
T1_MAX_MM_MAP_POINTS :: 20;

FT_VAR_AXIS_FLAG_HIDDEN :: 1;

/**************************************************************************
*
* @type:
*   FT_Int16
*
* @description:
*   A typedef for a 16bit signed integer type.
*/
FT_Int16 :: s16;

/**************************************************************************
*
* @type:
*   FT_UInt16
*
* @description:
*   A typedef for a 16bit unsigned integer type.
*/
FT_UInt16 :: u16;

FT_Int32 :: s32;
FT_UInt32 :: u32;

FT_Fast :: s32;
FT_UFast :: u32;

FT_Int64 :: s64;
FT_UInt64 :: u64;

/**************************************************************************
*
* @type:
*   FT_Memory
*
* @description:
*   A handle to a given memory manager object, defined with an
*   @FT_MemoryRec structure.
*
*/
FT_Memory :: *FT_MemoryRec_;

/**************************************************************************
*
* @functype:
*   FT_Alloc_Func
*
* @description:
*   A function used to allocate `size` bytes from `memory`.
*
* @input:
*   memory ::
*     A handle to the source memory manager.
*
*   size ::
*     The size in bytes to allocate.
*
* @return:
*   Address of new memory block.  0~in case of failure.
*
*/
FT_Alloc_Func :: #type (memory: FT_Memory, size: s64) -> *void #c_call;

/**************************************************************************
*
* @functype:
*   FT_Free_Func
*
* @description:
*   A function used to release a given block of memory.
*
* @input:
*   memory ::
*     A handle to the source memory manager.
*
*   block ::
*     The address of the target memory block.
*
*/
FT_Free_Func :: #type (memory: FT_Memory, block: *void) -> void #c_call;

/**************************************************************************
*
* @functype:
*   FT_Realloc_Func
*
* @description:
*   A function used to re-allocate a given block of memory.
*
* @input:
*   memory ::
*     A handle to the source memory manager.
*
*   cur_size ::
*     The block's current size in bytes.
*
*   new_size ::
*     The block's requested new size.
*
*   block ::
*     The block's current address.
*
* @return:
*   New block address.  0~in case of memory shortage.
*
* @note:
*   In case of error, the old block must still be available.
*
*/
FT_Realloc_Func :: #type (memory: FT_Memory, cur_size: s64, new_size: s64, block: *void) -> *void #c_call;

/**************************************************************************
*
* @struct:
*   FT_MemoryRec
*
* @description:
*   A structure used to describe a given memory manager to FreeType~2.
*
* @fields:
*   user ::
*     A generic typeless pointer for user data.
*
*   alloc ::
*     A pointer type to an allocation function.
*
*   free ::
*     A pointer type to an memory freeing function.
*
*   realloc ::
*     A pointer type to a reallocation function.
*
*/
FT_MemoryRec_ :: struct {
    user:    *void;
    alloc:   FT_Alloc_Func;
    free:    FT_Free_Func;
    realloc: FT_Realloc_Func;
}

/**************************************************************************
*
* @type:
*   FT_Stream
*
* @description:
*   A handle to an input stream.
*
* @also:
*   See @FT_StreamRec for the publicly accessible fields of a given stream
*   object.
*
*/
FT_Stream :: *FT_StreamRec_;

/**************************************************************************
*
* @struct:
*   FT_StreamDesc
*
* @description:
*   A union type used to store either a long or a pointer.  This is used
*   to store a file descriptor or a `FILE*` in an input stream.
*
*/
FT_StreamDesc_ :: struct {
    value: s64;

    #overlay (value) pointer: *void;
}

/**************************************************************************
*
* @struct:
*   FT_StreamDesc
*
* @description:
*   A union type used to store either a long or a pointer.  This is used
*   to store a file descriptor or a `FILE*` in an input stream.
*
*/
FT_StreamDesc :: FT_StreamDesc_;

/**************************************************************************
*
* @functype:
*   FT_Stream_IoFunc
*
* @description:
*   A function used to seek and read data from a given input stream.
*
* @input:
*   stream ::
*     A handle to the source stream.
*
*   offset ::
*     The offset from the start of the stream to seek to.
*
*   buffer ::
*     The address of the read buffer.
*
*   count ::
*     The number of bytes to read from the stream.
*
* @return:
*   If count >~0, return the number of bytes effectively read by the
*   stream (after seeking to `offset`).  If count ==~0, return the status
*   of the seek operation (non-zero indicates an error).
*
*/
FT_Stream_IoFunc :: #type (stream: FT_Stream, offset: u64, buffer: *u8, count: u64) -> u64 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Stream_CloseFunc
*
* @description:
*   A function used to close a given input stream.
*
* @input:
*  stream ::
*    A handle to the target stream.
*
*/
FT_Stream_CloseFunc :: #type (stream: FT_Stream) -> void #c_call;

/**************************************************************************
*
* @struct:
*   FT_StreamRec
*
* @description:
*   A structure used to describe an input stream.
*
* @input:
*   base ::
*     For memory-based streams, this is the address of the first stream
*     byte in memory.  This field should always be set to `NULL` for
*     disk-based streams.
*
*   size ::
*     The stream size in bytes.
*
*     In case of compressed streams where the size is unknown before
*     actually doing the decompression, the value is set to 0x7FFFFFFF.
*     (Note that this size value can occur for normal streams also; it is
*     thus just a hint.)
*
*   pos ::
*     The current position within the stream.
*
*   descriptor ::
*     This field is a union that can hold an integer or a pointer.  It is
*     used by stream implementations to store file descriptors or `FILE*`
*     pointers.
*
*   pathname ::
*     This field is completely ignored by FreeType.  However, it is often
*     useful during debugging to use it to store the stream's filename
*     (where available).
*
*   read ::
*     The stream's input function.
*
*   close ::
*     The stream's close function.
*
*   memory ::
*     The memory manager to use to preload frames.  This is set internally
*     by FreeType and shouldn't be touched by stream implementations.
*
*   cursor ::
*     This field is set and used internally by FreeType when parsing
*     frames.  In particular, the `FT_GET_XXX` macros use this instead of
*     the `pos` field.
*
*   limit ::
*     This field is set and used internally by FreeType when parsing
*     frames.
*
*/
FT_StreamRec_ :: struct {
    base:       *u8;
    size:       u64;
    pos:        u64;

    descriptor: FT_StreamDesc;
    pathname:   FT_StreamDesc;
    read:       FT_Stream_IoFunc;
    close:      FT_Stream_CloseFunc;

    memory:     FT_Memory;
    cursor:     *u8;
    limit:      *u8;
}

/**************************************************************************
*
* @struct:
*   FT_StreamRec
*
* @description:
*   A structure used to describe an input stream.
*
* @input:
*   base ::
*     For memory-based streams, this is the address of the first stream
*     byte in memory.  This field should always be set to `NULL` for
*     disk-based streams.
*
*   size ::
*     The stream size in bytes.
*
*     In case of compressed streams where the size is unknown before
*     actually doing the decompression, the value is set to 0x7FFFFFFF.
*     (Note that this size value can occur for normal streams also; it is
*     thus just a hint.)
*
*   pos ::
*     The current position within the stream.
*
*   descriptor ::
*     This field is a union that can hold an integer or a pointer.  It is
*     used by stream implementations to store file descriptors or `FILE*`
*     pointers.
*
*   pathname ::
*     This field is completely ignored by FreeType.  However, it is often
*     useful during debugging to use it to store the stream's filename
*     (where available).
*
*   read ::
*     The stream's input function.
*
*   close ::
*     The stream's close function.
*
*   memory ::
*     The memory manager to use to preload frames.  This is set internally
*     by FreeType and shouldn't be touched by stream implementations.
*
*   cursor ::
*     This field is set and used internally by FreeType when parsing
*     frames.  In particular, the `FT_GET_XXX` macros use this instead of
*     the `pos` field.
*
*   limit ::
*     This field is set and used internally by FreeType when parsing
*     frames.
*
*/
FT_StreamRec :: FT_StreamRec_;

/**************************************************************************
*
* @type:
*   FT_Pos
*
* @description:
*   The type FT_Pos is used to store vectorial coordinates.  Depending on
*   the context, these can represent distances in integer font units, or
*   16.16, or 26.6 fixed-point pixel coordinates.
*/
FT_Pos :: s64;

/**************************************************************************
*
* @struct:
*   FT_Vector
*
* @description:
*   A simple structure used to store a 2D vector; coordinates are of the
*   FT_Pos type.
*
* @fields:
*   x ::
*     The horizontal coordinate.
*   y ::
*     The vertical coordinate.
*/
FT_Vector_ :: struct {
    x: FT_Pos;
    y: FT_Pos;
}

/**************************************************************************
*
* @struct:
*   FT_Vector
*
* @description:
*   A simple structure used to store a 2D vector; coordinates are of the
*   FT_Pos type.
*
* @fields:
*   x ::
*     The horizontal coordinate.
*   y ::
*     The vertical coordinate.
*/
FT_Vector :: FT_Vector_;

/**************************************************************************
*
* @struct:
*   FT_BBox
*
* @description:
*   A structure used to hold an outline's bounding box, i.e., the
*   coordinates of its extrema in the horizontal and vertical directions.
*
* @fields:
*   xMin ::
*     The horizontal minimum (left-most).
*
*   yMin ::
*     The vertical minimum (bottom-most).
*
*   xMax ::
*     The horizontal maximum (right-most).
*
*   yMax ::
*     The vertical maximum (top-most).
*
* @note:
*   The bounding box is specified with the coordinates of the lower left
*   and the upper right corner.  In PostScript, those values are often
*   called (llx,lly) and (urx,ury), respectively.
*
*   If `yMin` is negative, this value gives the glyph's descender.
*   Otherwise, the glyph doesn't descend below the baseline.  Similarly,
*   if `ymax` is positive, this value gives the glyph's ascender.
*
*   `xMin` gives the horizontal distance from the glyph's origin to the
*   left edge of the glyph's bounding box.  If `xMin` is negative, the
*   glyph extends to the left of the origin.
*/
FT_BBox_ :: struct {
    xMin: FT_Pos;
    yMin: FT_Pos;
    xMax: FT_Pos;
    yMax: FT_Pos;
}

/**************************************************************************
*
* @struct:
*   FT_BBox
*
* @description:
*   A structure used to hold an outline's bounding box, i.e., the
*   coordinates of its extrema in the horizontal and vertical directions.
*
* @fields:
*   xMin ::
*     The horizontal minimum (left-most).
*
*   yMin ::
*     The vertical minimum (bottom-most).
*
*   xMax ::
*     The horizontal maximum (right-most).
*
*   yMax ::
*     The vertical maximum (top-most).
*
* @note:
*   The bounding box is specified with the coordinates of the lower left
*   and the upper right corner.  In PostScript, those values are often
*   called (llx,lly) and (urx,ury), respectively.
*
*   If `yMin` is negative, this value gives the glyph's descender.
*   Otherwise, the glyph doesn't descend below the baseline.  Similarly,
*   if `ymax` is positive, this value gives the glyph's ascender.
*
*   `xMin` gives the horizontal distance from the glyph's origin to the
*   left edge of the glyph's bounding box.  If `xMin` is negative, the
*   glyph extends to the left of the origin.
*/
FT_BBox :: FT_BBox_;

/**************************************************************************
*
* @enum:
*   FT_Pixel_Mode
*
* @description:
*   An enumeration type used to describe the format of pixels in a given
*   bitmap.  Note that additional formats may be added in the future.
*
* @values:
*   FT_PIXEL_MODE_NONE ::
*     Value~0 is reserved.
*
*   FT_PIXEL_MODE_MONO ::
*     A monochrome bitmap, using 1~bit per pixel.  Note that pixels are
*     stored in most-significant order (MSB), which means that the
*     left-most pixel in a byte has value 128.
*
*   FT_PIXEL_MODE_GRAY ::
*     An 8-bit bitmap, generally used to represent anti-aliased glyph
*     images.  Each pixel is stored in one byte.  Note that the number of
*     'gray' levels is stored in the `num_grays` field of the @FT_Bitmap
*     structure (it generally is 256).
*
*   FT_PIXEL_MODE_GRAY2 ::
*     A 2-bit per pixel bitmap, used to represent embedded anti-aliased
*     bitmaps in font files according to the OpenType specification.  We
*     haven't found a single font using this format, however.
*
*   FT_PIXEL_MODE_GRAY4 ::
*     A 4-bit per pixel bitmap, representing embedded anti-aliased bitmaps
*     in font files according to the OpenType specification.  We haven't
*     found a single font using this format, however.
*
*   FT_PIXEL_MODE_LCD ::
*     An 8-bit bitmap, representing RGB or BGR decimated glyph images used
*     for display on LCD displays; the bitmap is three times wider than
*     the original glyph image.  See also @FT_RENDER_MODE_LCD.
*
*   FT_PIXEL_MODE_LCD_V ::
*     An 8-bit bitmap, representing RGB or BGR decimated glyph images used
*     for display on rotated LCD displays; the bitmap is three times
*     taller than the original glyph image.  See also
*     @FT_RENDER_MODE_LCD_V.
*
*   FT_PIXEL_MODE_BGRA ::
*     [Since 2.5] An image with four 8-bit channels per pixel,
*     representing a color image (such as emoticons) with alpha channel.
*     For each pixel, the format is BGRA, which means, the blue channel
*     comes first in memory.  The color channels are pre-multiplied and in
*     the sRGB colorspace.  For example, full red at half-translucent
*     opacity will be represented as '00,00,80,80', not '00,00,FF,80'.
*     See also @FT_LOAD_COLOR.
*/
FT_Pixel_Mode_ :: enum u32 {
    NONE  :: 0;
    MONO  :: 1;
    GRAY  :: 2;
    GRAY2 :: 3;
    GRAY4 :: 4;
    LCD   :: 5;
    LCD_V :: 6;
    BGRA  :: 7;

    MAX   :: 8;

    FT_PIXEL_MODE_NONE  :: NONE;
    FT_PIXEL_MODE_MONO  :: MONO;
    FT_PIXEL_MODE_GRAY  :: GRAY;
    FT_PIXEL_MODE_GRAY2 :: GRAY2;
    FT_PIXEL_MODE_GRAY4 :: GRAY4;
    FT_PIXEL_MODE_LCD   :: LCD;
    FT_PIXEL_MODE_LCD_V :: LCD_V;
    FT_PIXEL_MODE_BGRA  :: BGRA;

    FT_PIXEL_MODE_MAX   :: MAX;
}

/**************************************************************************
*
* @enum:
*   FT_Pixel_Mode
*
* @description:
*   An enumeration type used to describe the format of pixels in a given
*   bitmap.  Note that additional formats may be added in the future.
*
* @values:
*   FT_PIXEL_MODE_NONE ::
*     Value~0 is reserved.
*
*   FT_PIXEL_MODE_MONO ::
*     A monochrome bitmap, using 1~bit per pixel.  Note that pixels are
*     stored in most-significant order (MSB), which means that the
*     left-most pixel in a byte has value 128.
*
*   FT_PIXEL_MODE_GRAY ::
*     An 8-bit bitmap, generally used to represent anti-aliased glyph
*     images.  Each pixel is stored in one byte.  Note that the number of
*     'gray' levels is stored in the `num_grays` field of the @FT_Bitmap
*     structure (it generally is 256).
*
*   FT_PIXEL_MODE_GRAY2 ::
*     A 2-bit per pixel bitmap, used to represent embedded anti-aliased
*     bitmaps in font files according to the OpenType specification.  We
*     haven't found a single font using this format, however.
*
*   FT_PIXEL_MODE_GRAY4 ::
*     A 4-bit per pixel bitmap, representing embedded anti-aliased bitmaps
*     in font files according to the OpenType specification.  We haven't
*     found a single font using this format, however.
*
*   FT_PIXEL_MODE_LCD ::
*     An 8-bit bitmap, representing RGB or BGR decimated glyph images used
*     for display on LCD displays; the bitmap is three times wider than
*     the original glyph image.  See also @FT_RENDER_MODE_LCD.
*
*   FT_PIXEL_MODE_LCD_V ::
*     An 8-bit bitmap, representing RGB or BGR decimated glyph images used
*     for display on rotated LCD displays; the bitmap is three times
*     taller than the original glyph image.  See also
*     @FT_RENDER_MODE_LCD_V.
*
*   FT_PIXEL_MODE_BGRA ::
*     [Since 2.5] An image with four 8-bit channels per pixel,
*     representing a color image (such as emoticons) with alpha channel.
*     For each pixel, the format is BGRA, which means, the blue channel
*     comes first in memory.  The color channels are pre-multiplied and in
*     the sRGB colorspace.  For example, full red at half-translucent
*     opacity will be represented as '00,00,80,80', not '00,00,FF,80'.
*     See also @FT_LOAD_COLOR.
*/
FT_Pixel_Mode :: FT_Pixel_Mode_;

/**************************************************************************
*
* @struct:
*   FT_Bitmap
*
* @description:
*   A structure used to describe a bitmap or pixmap to the raster.  Note
*   that we now manage pixmaps of various depths through the `pixel_mode`
*   field.
*
* @fields:
*   rows ::
*     The number of bitmap rows.
*
*   width ::
*     The number of pixels in bitmap row.
*
*   pitch ::
*     The pitch's absolute value is the number of bytes taken by one
*     bitmap row, including padding.  However, the pitch is positive when
*     the bitmap has a 'down' flow, and negative when it has an 'up' flow.
*     In all cases, the pitch is an offset to add to a bitmap pointer in
*     order to go down one row.
*
*     Note that 'padding' means the alignment of a bitmap to a byte
*     border, and FreeType functions normally align to the smallest
*     possible integer value.
*
*     For the B/W rasterizer, `pitch` is always an even number.
*
*     To change the pitch of a bitmap (say, to make it a multiple of 4),
*     use @FT_Bitmap_Convert.  Alternatively, you might use callback
*     functions to directly render to the application's surface; see the
*     file `example2.cpp` in the tutorial for a demonstration.
*
*   buffer ::
*     A typeless pointer to the bitmap buffer.  This value should be
*     aligned on 32-bit boundaries in most cases.
*
*   num_grays ::
*     This field is only used with @FT_PIXEL_MODE_GRAY; it gives the
*     number of gray levels used in the bitmap.
*
*   pixel_mode ::
*     The pixel mode, i.e., how pixel bits are stored.  See @FT_Pixel_Mode
*     for possible values.
*
*   palette_mode ::
*     This field is intended for paletted pixel modes; it indicates how
*     the palette is stored.  Not used currently.
*
*   palette ::
*     A typeless pointer to the bitmap palette; this field is intended for
*     paletted pixel modes.  Not used currently.
*
* @note:
*   `width` and `rows` refer to the *physical* size of the bitmap, not the
*   *logical* one.  For example, if @FT_Pixel_Mode is set to
*   `FT_PIXEL_MODE_LCD`, the logical width is a just a third of the
*   physical one.
*
*   An empty bitmap with a NULL `buffer` is valid, with `rows` and/or
*   `pitch` also set to 0.  Such bitmaps might be produced while rendering
*   empty or degenerate outlines.
*/
FT_Bitmap_ :: struct {
    rows:         u32;
    width:        u32;
    pitch:        s32;
    buffer:       *u8;
    num_grays:    u16;
    pixel_mode:   u8;
    palette_mode: u8;
    palette:      *void;
}

/**************************************************************************
*
* @struct:
*   FT_Bitmap
*
* @description:
*   A structure used to describe a bitmap or pixmap to the raster.  Note
*   that we now manage pixmaps of various depths through the `pixel_mode`
*   field.
*
* @fields:
*   rows ::
*     The number of bitmap rows.
*
*   width ::
*     The number of pixels in bitmap row.
*
*   pitch ::
*     The pitch's absolute value is the number of bytes taken by one
*     bitmap row, including padding.  However, the pitch is positive when
*     the bitmap has a 'down' flow, and negative when it has an 'up' flow.
*     In all cases, the pitch is an offset to add to a bitmap pointer in
*     order to go down one row.
*
*     Note that 'padding' means the alignment of a bitmap to a byte
*     border, and FreeType functions normally align to the smallest
*     possible integer value.
*
*     For the B/W rasterizer, `pitch` is always an even number.
*
*     To change the pitch of a bitmap (say, to make it a multiple of 4),
*     use @FT_Bitmap_Convert.  Alternatively, you might use callback
*     functions to directly render to the application's surface; see the
*     file `example2.cpp` in the tutorial for a demonstration.
*
*   buffer ::
*     A typeless pointer to the bitmap buffer.  This value should be
*     aligned on 32-bit boundaries in most cases.
*
*   num_grays ::
*     This field is only used with @FT_PIXEL_MODE_GRAY; it gives the
*     number of gray levels used in the bitmap.
*
*   pixel_mode ::
*     The pixel mode, i.e., how pixel bits are stored.  See @FT_Pixel_Mode
*     for possible values.
*
*   palette_mode ::
*     This field is intended for paletted pixel modes; it indicates how
*     the palette is stored.  Not used currently.
*
*   palette ::
*     A typeless pointer to the bitmap palette; this field is intended for
*     paletted pixel modes.  Not used currently.
*
* @note:
*   `width` and `rows` refer to the *physical* size of the bitmap, not the
*   *logical* one.  For example, if @FT_Pixel_Mode is set to
*   `FT_PIXEL_MODE_LCD`, the logical width is a just a third of the
*   physical one.
*
*   An empty bitmap with a NULL `buffer` is valid, with `rows` and/or
*   `pitch` also set to 0.  Such bitmaps might be produced while rendering
*   empty or degenerate outlines.
*/
FT_Bitmap :: FT_Bitmap_;

/**************************************************************************
*
* @struct:
*   FT_Outline
*
* @description:
*   This structure is used to describe an outline to the scan-line
*   converter.
*
* @fields:
*   n_contours ::
*     The number of contours in the outline.
*
*   n_points ::
*     The number of points in the outline.
*
*   points ::
*     A pointer to an array of `n_points` @FT_Vector elements, giving the
*     outline's point coordinates.
*
*   tags ::
*     A pointer to an array of `n_points` chars, giving each outline
*     point's type.
*
*     If bit~0 is unset, the point is 'off' the curve, i.e., a Bezier
*     control point, while it is 'on' if set.
*
*     Bit~1 is meaningful for 'off' points only.  If set, it indicates a
*     third-order Bezier arc control point; and a second-order control
*     point if unset.
*
*     If bit~2 is set, bits 5-7 contain the drop-out mode (as defined in
*     the OpenType specification; the value is the same as the argument to
*     the 'SCANTYPE' instruction).
*
*     Bits 3 and~4 are reserved for internal purposes.
*
*   contours ::
*     An array of `n_contours` shorts, giving the end point of each
*     contour within the outline.  For example, the first contour is
*     defined by the points '0' to `contours[0]`, the second one is
*     defined by the points `contours[0]+1` to `contours[1]`, etc.
*
*   flags ::
*     A set of bit flags used to characterize the outline and give hints
*     to the scan-converter and hinter on how to convert/grid-fit it.  See
*     @FT_OUTLINE_XXX.
*
* @note:
*   The B/W rasterizer only checks bit~2 in the `tags` array for the first
*   point of each contour.  The drop-out mode as given with
*   @FT_OUTLINE_IGNORE_DROPOUTS, @FT_OUTLINE_SMART_DROPOUTS, and
*   @FT_OUTLINE_INCLUDE_STUBS in `flags` is then overridden.
*/
FT_Outline_ :: struct {
    n_contours: u16; /* number of contours in glyph        */
    n_points:   u16; /* number of points in the glyph      */

    points:     *FT_Vector; /* the outline's points               */
    tags:       *u8; /* the points flags                   */
    contours:   *u16; /* the contour end points             */

    flags:      s32; /* outline masks                      */
}

/**************************************************************************
*
* @struct:
*   FT_Outline
*
* @description:
*   This structure is used to describe an outline to the scan-line
*   converter.
*
* @fields:
*   n_contours ::
*     The number of contours in the outline.
*
*   n_points ::
*     The number of points in the outline.
*
*   points ::
*     A pointer to an array of `n_points` @FT_Vector elements, giving the
*     outline's point coordinates.
*
*   tags ::
*     A pointer to an array of `n_points` chars, giving each outline
*     point's type.
*
*     If bit~0 is unset, the point is 'off' the curve, i.e., a Bezier
*     control point, while it is 'on' if set.
*
*     Bit~1 is meaningful for 'off' points only.  If set, it indicates a
*     third-order Bezier arc control point; and a second-order control
*     point if unset.
*
*     If bit~2 is set, bits 5-7 contain the drop-out mode (as defined in
*     the OpenType specification; the value is the same as the argument to
*     the 'SCANTYPE' instruction).
*
*     Bits 3 and~4 are reserved for internal purposes.
*
*   contours ::
*     An array of `n_contours` shorts, giving the end point of each
*     contour within the outline.  For example, the first contour is
*     defined by the points '0' to `contours[0]`, the second one is
*     defined by the points `contours[0]+1` to `contours[1]`, etc.
*
*   flags ::
*     A set of bit flags used to characterize the outline and give hints
*     to the scan-converter and hinter on how to convert/grid-fit it.  See
*     @FT_OUTLINE_XXX.
*
* @note:
*   The B/W rasterizer only checks bit~2 in the `tags` array for the first
*   point of each contour.  The drop-out mode as given with
*   @FT_OUTLINE_IGNORE_DROPOUTS, @FT_OUTLINE_SMART_DROPOUTS, and
*   @FT_OUTLINE_INCLUDE_STUBS in `flags` is then overridden.
*/
FT_Outline :: FT_Outline_;

/**************************************************************************
*
* @functype:
*   FT_Outline_MoveToFunc
*
* @description:
*   A function pointer type used to describe the signature of a 'move to'
*   function during outline walking/decomposition.
*
*   A 'move to' is emitted to start a new contour in an outline.
*
* @input:
*   to ::
*     A pointer to the target point of the 'move to'.
*
*   user ::
*     A typeless pointer, which is passed from the caller of the
*     decomposition function.
*
* @return:
*   Error code.  0~means success.
*/
FT_Outline_MoveToFunc :: #type (to: *FT_Vector, user: *void) -> s32 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Outline_LineToFunc
*
* @description:
*   A function pointer type used to describe the signature of a 'line to'
*   function during outline walking/decomposition.
*
*   A 'line to' is emitted to indicate a segment in the outline.
*
* @input:
*   to ::
*     A pointer to the target point of the 'line to'.
*
*   user ::
*     A typeless pointer, which is passed from the caller of the
*     decomposition function.
*
* @return:
*   Error code.  0~means success.
*/
FT_Outline_LineToFunc :: #type (to: *FT_Vector, user: *void) -> s32 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Outline_ConicToFunc
*
* @description:
*   A function pointer type used to describe the signature of a 'conic to'
*   function during outline walking or decomposition.
*
*   A 'conic to' is emitted to indicate a second-order Bezier arc in the
*   outline.
*
* @input:
*   control ::
*     An intermediate control point between the last position and the new
*     target in `to`.
*
*   to ::
*     A pointer to the target end point of the conic arc.
*
*   user ::
*     A typeless pointer, which is passed from the caller of the
*     decomposition function.
*
* @return:
*   Error code.  0~means success.
*/
FT_Outline_ConicToFunc :: #type (control: *FT_Vector, to: *FT_Vector, user: *void) -> s32 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Outline_CubicToFunc
*
* @description:
*   A function pointer type used to describe the signature of a 'cubic to'
*   function during outline walking or decomposition.
*
*   A 'cubic to' is emitted to indicate a third-order Bezier arc.
*
* @input:
*   control1 ::
*     A pointer to the first Bezier control point.
*
*   control2 ::
*     A pointer to the second Bezier control point.
*
*   to ::
*     A pointer to the target end point.
*
*   user ::
*     A typeless pointer, which is passed from the caller of the
*     decomposition function.
*
* @return:
*   Error code.  0~means success.
*/
FT_Outline_CubicToFunc :: #type (control1: *FT_Vector, control2: *FT_Vector, to: *FT_Vector, user: *void) -> s32 #c_call;

/**************************************************************************
*
* @struct:
*   FT_Outline_Funcs
*
* @description:
*   A structure to hold various function pointers used during outline
*   decomposition in order to emit segments, conic, and cubic Beziers.
*
* @fields:
*   move_to ::
*     The 'move to' emitter.
*
*   line_to ::
*     The segment emitter.
*
*   conic_to ::
*     The second-order Bezier arc emitter.
*
*   cubic_to ::
*     The third-order Bezier arc emitter.
*
*   shift ::
*     The shift that is applied to coordinates before they are sent to the
*     emitter.
*
*   delta ::
*     The delta that is applied to coordinates before they are sent to the
*     emitter, but after the shift.
*
* @note:
*   The point coordinates sent to the emitters are the transformed version
*   of the original coordinates (this is important for high accuracy
*   during scan-conversion).  The transformation is simple:
*
*   ```
*     x' = (x << shift) - delta
*     y' = (y << shift) - delta
*   ```
*
*   Set the values of `shift` and `delta` to~0 to get the original point
*   coordinates.
*/
FT_Outline_Funcs_ :: struct {
    move_to:  FT_Outline_MoveToFunc;
    line_to:  FT_Outline_LineToFunc;
    conic_to: FT_Outline_ConicToFunc;
    cubic_to: FT_Outline_CubicToFunc;

    shift:    s32;
    delta:    FT_Pos;
}

/**************************************************************************
*
* @struct:
*   FT_Outline_Funcs
*
* @description:
*   A structure to hold various function pointers used during outline
*   decomposition in order to emit segments, conic, and cubic Beziers.
*
* @fields:
*   move_to ::
*     The 'move to' emitter.
*
*   line_to ::
*     The segment emitter.
*
*   conic_to ::
*     The second-order Bezier arc emitter.
*
*   cubic_to ::
*     The third-order Bezier arc emitter.
*
*   shift ::
*     The shift that is applied to coordinates before they are sent to the
*     emitter.
*
*   delta ::
*     The delta that is applied to coordinates before they are sent to the
*     emitter, but after the shift.
*
* @note:
*   The point coordinates sent to the emitters are the transformed version
*   of the original coordinates (this is important for high accuracy
*   during scan-conversion).  The transformation is simple:
*
*   ```
*     x' = (x << shift) - delta
*     y' = (y << shift) - delta
*   ```
*
*   Set the values of `shift` and `delta` to~0 to get the original point
*   coordinates.
*/
FT_Outline_Funcs :: FT_Outline_Funcs_;

/**************************************************************************
*
* @enum:
*   FT_Glyph_Format
*
* @description:
*   An enumeration type used to describe the format of a given glyph
*   image.  Note that this version of FreeType only supports two image
*   formats, even though future font drivers will be able to register
*   their own format.
*
* @values:
*   FT_GLYPH_FORMAT_NONE ::
*     The value~0 is reserved.
*
*   FT_GLYPH_FORMAT_COMPOSITE ::
*     The glyph image is a composite of several other images.  This format
*     is _only_ used with @FT_LOAD_NO_RECURSE, and is used to report
*     compound glyphs (like accented characters).
*
*   FT_GLYPH_FORMAT_BITMAP ::
*     The glyph image is a bitmap, and can be described as an @FT_Bitmap.
*     You generally need to access the `bitmap` field of the
*     @FT_GlyphSlotRec structure to read it.
*
*   FT_GLYPH_FORMAT_OUTLINE ::
*     The glyph image is a vectorial outline made of line segments and
*     Bezier arcs; it can be described as an @FT_Outline; you generally
*     want to access the `outline` field of the @FT_GlyphSlotRec structure
*     to read it.
*
*   FT_GLYPH_FORMAT_PLOTTER ::
*     The glyph image is a vectorial path with no inside and outside
*     contours.  Some Type~1 fonts, like those in the Hershey family,
*     contain glyphs in this format.  These are described as @FT_Outline,
*     but FreeType isn't currently capable of rendering them correctly.
*
*   FT_GLYPH_FORMAT_SVG ::
*     [Since 2.12] The glyph is represented by an SVG document in the
*     'SVG~' table.
*/
FT_Glyph_Format_ :: enum u32 {
    NONE      :: 0;

    COMPOSITE :: 1668246896;
    BITMAP    :: 1651078259;
    OUTLINE   :: 1869968492;
    PLOTTER   :: 1886154612;
    SVG       :: 1398163232;

    FT_GLYPH_FORMAT_NONE      :: NONE;

    FT_GLYPH_FORMAT_COMPOSITE :: COMPOSITE;
    FT_GLYPH_FORMAT_BITMAP    :: BITMAP;
    FT_GLYPH_FORMAT_OUTLINE   :: OUTLINE;
    FT_GLYPH_FORMAT_PLOTTER   :: PLOTTER;
    FT_GLYPH_FORMAT_SVG       :: SVG;
}

/**************************************************************************
*
* @enum:
*   FT_Glyph_Format
*
* @description:
*   An enumeration type used to describe the format of a given glyph
*   image.  Note that this version of FreeType only supports two image
*   formats, even though future font drivers will be able to register
*   their own format.
*
* @values:
*   FT_GLYPH_FORMAT_NONE ::
*     The value~0 is reserved.
*
*   FT_GLYPH_FORMAT_COMPOSITE ::
*     The glyph image is a composite of several other images.  This format
*     is _only_ used with @FT_LOAD_NO_RECURSE, and is used to report
*     compound glyphs (like accented characters).
*
*   FT_GLYPH_FORMAT_BITMAP ::
*     The glyph image is a bitmap, and can be described as an @FT_Bitmap.
*     You generally need to access the `bitmap` field of the
*     @FT_GlyphSlotRec structure to read it.
*
*   FT_GLYPH_FORMAT_OUTLINE ::
*     The glyph image is a vectorial outline made of line segments and
*     Bezier arcs; it can be described as an @FT_Outline; you generally
*     want to access the `outline` field of the @FT_GlyphSlotRec structure
*     to read it.
*
*   FT_GLYPH_FORMAT_PLOTTER ::
*     The glyph image is a vectorial path with no inside and outside
*     contours.  Some Type~1 fonts, like those in the Hershey family,
*     contain glyphs in this format.  These are described as @FT_Outline,
*     but FreeType isn't currently capable of rendering them correctly.
*
*   FT_GLYPH_FORMAT_SVG ::
*     [Since 2.12] The glyph is represented by an SVG document in the
*     'SVG~' table.
*/
FT_Glyph_Format :: FT_Glyph_Format_;

/**************************************************************************
*
* @struct:
*   FT_Span
*
* @description:
*   A structure to model a single span of consecutive pixels when
*   rendering an anti-aliased bitmap.
*
* @fields:
*   x ::
*     The span's horizontal start position.
*
*   len ::
*     The span's length in pixels.
*
*   coverage ::
*     The span color/coverage, ranging from 0 (background) to 255
*     (foreground).
*
* @note:
*   This structure is used by the span drawing callback type named
*   @FT_SpanFunc that takes the y~coordinate of the span as a parameter.
*
*   The anti-aliased rasterizer produces coverage values from 0 to 255,
*   that is, from completely transparent to completely opaque.
*/
FT_Span_ :: struct {
    x:        u16;
    len:      u16;
    coverage: u8;
}

/**************************************************************************
*
* @struct:
*   FT_Span
*
* @description:
*   A structure to model a single span of consecutive pixels when
*   rendering an anti-aliased bitmap.
*
* @fields:
*   x ::
*     The span's horizontal start position.
*
*   len ::
*     The span's length in pixels.
*
*   coverage ::
*     The span color/coverage, ranging from 0 (background) to 255
*     (foreground).
*
* @note:
*   This structure is used by the span drawing callback type named
*   @FT_SpanFunc that takes the y~coordinate of the span as a parameter.
*
*   The anti-aliased rasterizer produces coverage values from 0 to 255,
*   that is, from completely transparent to completely opaque.
*/
FT_Span :: FT_Span_;

/**************************************************************************
*
* @functype:
*   FT_SpanFunc
*
* @description:
*   A function used as a call-back by the anti-aliased renderer in order
*   to let client applications draw themselves the pixel spans on each
*   scan line.
*
* @input:
*   y ::
*     The scanline's upward y~coordinate.
*
*   count ::
*     The number of spans to draw on this scanline.
*
*   spans ::
*     A table of `count` spans to draw on the scanline.
*
*   user ::
*     User-supplied data that is passed to the callback.
*
* @note:
*   This callback allows client applications to directly render the spans
*   of the anti-aliased bitmap to any kind of surfaces.
*
*   This can be used to write anti-aliased outlines directly to a given
*   background bitmap using alpha compositing.  It can also be used for
*   oversampling and averaging.
*/
FT_SpanFunc :: #type (y: s32, count: s32, spans: *FT_Span, user: *void) -> void #c_call;

/**************************************************************************
*
* @functype:
*   FT_Raster_BitTest_Func
*
* @description:
*   Deprecated, unimplemented.
*/
FT_Raster_BitTest_Func :: #type (y: s32, x: s32, user: *void) -> s32 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Raster_BitSet_Func
*
* @description:
*   Deprecated, unimplemented.
*/
FT_Raster_BitSet_Func :: #type (y: s32, x: s32, user: *void) -> void #c_call;

/**************************************************************************
*
* @struct:
*   FT_Raster_Params
*
* @description:
*   A structure to hold the parameters used by a raster's render function,
*   passed as an argument to @FT_Outline_Render.
*
* @fields:
*   target ::
*     The target bitmap.
*
*   source ::
*     A pointer to the source glyph image (e.g., an @FT_Outline).
*
*   flags ::
*     The rendering flags.
*
*   gray_spans ::
*     The gray span drawing callback.
*
*   black_spans ::
*     Unused.
*
*   bit_test ::
*     Unused.
*
*   bit_set ::
*     Unused.
*
*   user ::
*     User-supplied data that is passed to each drawing callback.
*
*   clip_box ::
*     An optional span clipping box expressed in _integer_ pixels
*     (not in 26.6 fixed-point units).
*
* @note:
*   The @FT_RASTER_FLAG_AA bit flag must be set in the `flags` to
*   generate an anti-aliased glyph bitmap, otherwise a monochrome bitmap
*   is generated.  The `target` should have appropriate pixel mode and its
*   dimensions define the clipping region.
*
*   If both @FT_RASTER_FLAG_AA and @FT_RASTER_FLAG_DIRECT bit flags
*   are set in `flags`, the raster calls an @FT_SpanFunc callback
*   `gray_spans` with `user` data as an argument ignoring `target`.  This
*   allows direct composition over a pre-existing user surface to perform
*   the span drawing and composition.  To optionally clip the spans, set
*   the @FT_RASTER_FLAG_CLIP flag and `clip_box`.  The monochrome raster
*   does not support the direct mode.
*
*   The gray-level rasterizer always uses 256 gray levels.  If you want
*   fewer gray levels, you have to use @FT_RASTER_FLAG_DIRECT and reduce
*   the levels in the callback function.
*/
FT_Raster_Params_ :: struct {
    target:      *FT_Bitmap;
    source:      *void;
    flags:       s32;
    gray_spans:  FT_SpanFunc;
    black_spans: FT_SpanFunc; /* unused */
    bit_test:    FT_Raster_BitTest_Func; /* unused */
    bit_set:     FT_Raster_BitSet_Func; /* unused */
    user:        *void;
    clip_box:    FT_BBox;
}

/**************************************************************************
*
* @struct:
*   FT_Raster_Params
*
* @description:
*   A structure to hold the parameters used by a raster's render function,
*   passed as an argument to @FT_Outline_Render.
*
* @fields:
*   target ::
*     The target bitmap.
*
*   source ::
*     A pointer to the source glyph image (e.g., an @FT_Outline).
*
*   flags ::
*     The rendering flags.
*
*   gray_spans ::
*     The gray span drawing callback.
*
*   black_spans ::
*     Unused.
*
*   bit_test ::
*     Unused.
*
*   bit_set ::
*     Unused.
*
*   user ::
*     User-supplied data that is passed to each drawing callback.
*
*   clip_box ::
*     An optional span clipping box expressed in _integer_ pixels
*     (not in 26.6 fixed-point units).
*
* @note:
*   The @FT_RASTER_FLAG_AA bit flag must be set in the `flags` to
*   generate an anti-aliased glyph bitmap, otherwise a monochrome bitmap
*   is generated.  The `target` should have appropriate pixel mode and its
*   dimensions define the clipping region.
*
*   If both @FT_RASTER_FLAG_AA and @FT_RASTER_FLAG_DIRECT bit flags
*   are set in `flags`, the raster calls an @FT_SpanFunc callback
*   `gray_spans` with `user` data as an argument ignoring `target`.  This
*   allows direct composition over a pre-existing user surface to perform
*   the span drawing and composition.  To optionally clip the spans, set
*   the @FT_RASTER_FLAG_CLIP flag and `clip_box`.  The monochrome raster
*   does not support the direct mode.
*
*   The gray-level rasterizer always uses 256 gray levels.  If you want
*   fewer gray levels, you have to use @FT_RASTER_FLAG_DIRECT and reduce
*   the levels in the callback function.
*/
FT_Raster_Params :: FT_Raster_Params_;

FT_RasterRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Raster
*
* @description:
*   An opaque handle (pointer) to a raster object.  Each object can be
*   used independently to convert an outline into a bitmap or pixmap.
*
* @note:
*   In FreeType 2, all rasters are now encapsulated within specific
*   @FT_Renderer modules and only used in their context.
*
*/
FT_Raster :: *FT_RasterRec_;

/**************************************************************************
*
* @functype:
*   FT_Raster_NewFunc
*
* @description:
*   A function used to create a new raster object.
*
* @input:
*   memory ::
*     A handle to the memory allocator.
*
* @output:
*   raster ::
*     A handle to the new raster object.
*
* @return:
*   Error code.  0~means success.
*
* @note:
*   The `memory` parameter is a typeless pointer in order to avoid
*   un-wanted dependencies on the rest of the FreeType code.  In practice,
*   it is an @FT_Memory object, i.e., a handle to the standard FreeType
*   memory allocator.  However, this field can be completely ignored by a
*   given raster implementation.
*/
FT_Raster_NewFunc :: #type (memory: *void, raster: *FT_Raster) -> s32 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Raster_DoneFunc
*
* @description:
*   A function used to destroy a given raster object.
*
* @input:
*   raster ::
*     A handle to the raster object.
*/
FT_Raster_DoneFunc :: #type (raster: FT_Raster) -> void #c_call;

/**************************************************************************
*
* @functype:
*   FT_Raster_ResetFunc
*
* @description:
*   FreeType used to provide an area of memory called the 'render pool'
*   available to all registered rasterizers.  This was not thread safe,
*   however, and now FreeType never allocates this pool.
*
*   This function is called after a new raster object is created.
*
* @input:
*   raster ::
*     A handle to the new raster object.
*
*   pool_base ::
*     Previously, the address in memory of the render pool.  Set this to
*     `NULL`.
*
*   pool_size ::
*     Previously, the size in bytes of the render pool.  Set this to 0.
*
* @note:
*   Rasterizers should rely on dynamic or stack allocation if they want to
*   (a handle to the memory allocator is passed to the rasterizer
*   constructor).
*/
FT_Raster_ResetFunc :: #type (raster: FT_Raster, pool_base: *u8, pool_size: u64) -> void #c_call;

/**************************************************************************
*
* @functype:
*   FT_Raster_SetModeFunc
*
* @description:
*   This function is a generic facility to change modes or attributes in a
*   given raster.  This can be used for debugging purposes, or simply to
*   allow implementation-specific 'features' in a given raster module.
*
* @input:
*   raster ::
*     A handle to the new raster object.
*
*   mode ::
*     A 4-byte tag used to name the mode or property.
*
*   args ::
*     A pointer to the new mode/property to use.
*/
FT_Raster_SetModeFunc :: #type (raster: FT_Raster, mode: u64, args: *void) -> s32 #c_call;

/**************************************************************************
*
* @functype:
*   FT_Raster_RenderFunc
*
* @description:
*   Invoke a given raster to scan-convert a given glyph image into a
*   target bitmap.
*
* @input:
*   raster ::
*     A handle to the raster object.
*
*   params ::
*     A pointer to an @FT_Raster_Params structure used to store the
*     rendering parameters.
*
* @return:
*   Error code.  0~means success.
*
* @note:
*   The exact format of the source image depends on the raster's glyph
*   format defined in its @FT_Raster_Funcs structure.  It can be an
*   @FT_Outline or anything else in order to support a large array of
*   glyph formats.
*
*   Note also that the render function can fail and return a
*   `FT_Err_Unimplemented_Feature` error code if the raster used does not
*   support direct composition.
*/
FT_Raster_RenderFunc :: #type (raster: FT_Raster, params: *FT_Raster_Params) -> s32 #c_call;

/**************************************************************************
*
* @struct:
*   FT_Raster_Funcs
*
* @description:
*  A structure used to describe a given raster class to the library.
*
* @fields:
*   glyph_format ::
*     The supported glyph format for this raster.
*
*   raster_new ::
*     The raster constructor.
*
*   raster_reset ::
*     Used to reset the render pool within the raster.
*
*   raster_render ::
*     A function to render a glyph into a given bitmap.
*
*   raster_done ::
*     The raster destructor.
*/
FT_Raster_Funcs_ :: struct {
    glyph_format:    FT_Glyph_Format;

    raster_new:      FT_Raster_NewFunc;
    raster_reset:    FT_Raster_ResetFunc;
    raster_set_mode: FT_Raster_SetModeFunc;
    raster_render:   FT_Raster_RenderFunc;
    raster_done:     FT_Raster_DoneFunc;
}

/**************************************************************************
*
* @struct:
*   FT_Raster_Funcs
*
* @description:
*  A structure used to describe a given raster class to the library.
*
* @fields:
*   glyph_format ::
*     The supported glyph format for this raster.
*
*   raster_new ::
*     The raster constructor.
*
*   raster_reset ::
*     Used to reset the render pool within the raster.
*
*   raster_render ::
*     A function to render a glyph into a given bitmap.
*
*   raster_done ::
*     The raster destructor.
*/
FT_Raster_Funcs :: FT_Raster_Funcs_;

/**************************************************************************
*
* @type:
*   FT_Bool
*
* @description:
*   A typedef of unsigned char, used for simple booleans.  As usual,
*   values 1 and~0 represent true and false, respectively.
*/
FT_Bool :: u8;

/**************************************************************************
*
* @type:
*   FT_FWord
*
* @description:
*   A signed 16-bit integer used to store a distance in original font
*   units.
*/
FT_FWord :: s16;

/**************************************************************************
*
* @type:
*   FT_UFWord
*
* @description:
*   An unsigned 16-bit integer used to store a distance in original font
*   units.
*/
FT_UFWord :: u16;

/**************************************************************************
*
* @type:
*   FT_Char
*
* @description:
*   A simple typedef for the _signed_ char type.
*/
FT_Char :: s8;

/**************************************************************************
*
* @type:
*   FT_Byte
*
* @description:
*   A simple typedef for the _unsigned_ char type.
*/
FT_Byte :: u8;

/**************************************************************************
*
* @type:
*   FT_Bytes
*
* @description:
*   A typedef for constant memory areas.
*/
FT_Bytes :: *FT_Byte;

/**************************************************************************
*
* @type:
*   FT_Tag
*
* @description:
*   A typedef for 32-bit tags (as used in the SFNT format).
*/
FT_Tag :: FT_UInt32;

/**************************************************************************
*
* @type:
*   FT_String
*
* @description:
*   A simple typedef for the char type, usually used for strings.
*/
FT_String :: u8;

/**************************************************************************
*
* @type:
*   FT_Short
*
* @description:
*   A typedef for signed short.
*/
FT_Short :: s16;

/**************************************************************************
*
* @type:
*   FT_UShort
*
* @description:
*   A typedef for unsigned short.
*/
FT_UShort :: u16;

/**************************************************************************
*
* @type:
*   FT_Int
*
* @description:
*   A typedef for the int type.
*/
FT_Int :: s32;

/**************************************************************************
*
* @type:
*   FT_UInt
*
* @description:
*   A typedef for the unsigned int type.
*/
FT_UInt :: u32;

/**************************************************************************
*
* @type:
*   FT_Long
*
* @description:
*   A typedef for signed long.
*/
FT_Long :: s64;

/**************************************************************************
*
* @type:
*   FT_ULong
*
* @description:
*   A typedef for unsigned long.
*/
FT_ULong :: u64;

/**************************************************************************
*
* @type:
*   FT_F2Dot14
*
* @description:
*   A signed 2.14 fixed-point type used for unit vectors.
*/
FT_F2Dot14 :: s16;

/**************************************************************************
*
* @type:
*   FT_F26Dot6
*
* @description:
*   A signed 26.6 fixed-point type used for vectorial pixel coordinates.
*/
FT_F26Dot6 :: s64;

/**************************************************************************
*
* @type:
*   FT_Fixed
*
* @description:
*   This type is used to store 16.16 fixed-point values, like scaling
*   values or matrix coefficients.
*/
FT_Fixed :: s64;

/**************************************************************************
*
* @type:
*   FT_Error
*
* @description:
*   The FreeType error code type.  A value of~0 is always interpreted as a
*   successful operation.
*/
FT_Error :: s32;

/**************************************************************************
*
* @type:
*   FT_Pointer
*
* @description:
*   A simple typedef for a typeless pointer.
*/
FT_Pointer :: *void;

/**************************************************************************
*
* @type:
*   FT_Offset
*
* @description:
*   This is equivalent to the ANSI~C `size_t` type, i.e., the largest
*   _unsigned_ integer type used to express a file size or position, or a
*   memory block size.
*/
FT_Offset :: u64;

/**************************************************************************
*
* @type:
*   FT_PtrDist
*
* @description:
*   This is equivalent to the ANSI~C `ptrdiff_t` type, i.e., the largest
*   _signed_ integer type used to express the distance between two
*   pointers.
*/
FT_PtrDist :: ptrdiff_t;

/**************************************************************************
*
* @struct:
*   FT_UnitVector
*
* @description:
*   A simple structure used to store a 2D vector unit vector.  Uses
*   FT_F2Dot14 types.
*
* @fields:
*   x ::
*     Horizontal coordinate.
*
*   y ::
*     Vertical coordinate.
*/
FT_UnitVector_ :: struct {
    x: FT_F2Dot14;
    y: FT_F2Dot14;
}

/**************************************************************************
*
* @struct:
*   FT_UnitVector
*
* @description:
*   A simple structure used to store a 2D vector unit vector.  Uses
*   FT_F2Dot14 types.
*
* @fields:
*   x ::
*     Horizontal coordinate.
*
*   y ::
*     Vertical coordinate.
*/
FT_UnitVector :: FT_UnitVector_;

/**************************************************************************
*
* @struct:
*   FT_Matrix
*
* @description:
*   A simple structure used to store a 2x2 matrix.  Coefficients are in
*   16.16 fixed-point format.  The computation performed is:
*
*   ```
*     x' = x*xx + y*xy
*     y' = x*yx + y*yy
*   ```
*
* @fields:
*   xx ::
*     Matrix coefficient.
*
*   xy ::
*     Matrix coefficient.
*
*   yx ::
*     Matrix coefficient.
*
*   yy ::
*     Matrix coefficient.
*/
FT_Matrix_ :: struct {
    _xx: FT_Fixed;
    xy:  FT_Fixed;
    yx:  FT_Fixed;
    yy:  FT_Fixed;
}

/**************************************************************************
*
* @struct:
*   FT_Matrix
*
* @description:
*   A simple structure used to store a 2x2 matrix.  Coefficients are in
*   16.16 fixed-point format.  The computation performed is:
*
*   ```
*     x' = x*xx + y*xy
*     y' = x*yx + y*yy
*   ```
*
* @fields:
*   xx ::
*     Matrix coefficient.
*
*   xy ::
*     Matrix coefficient.
*
*   yx ::
*     Matrix coefficient.
*
*   yy ::
*     Matrix coefficient.
*/
FT_Matrix :: FT_Matrix_;

/**************************************************************************
*
* @struct:
*   FT_Data
*
* @description:
*   Read-only binary data represented as a pointer and a length.
*
* @fields:
*   pointer ::
*     The data.
*
*   length ::
*     The length of the data in bytes.
*/
FT_Data_ :: struct {
    pointer: *FT_Byte;
    length:  FT_UInt;
}

/**************************************************************************
*
* @struct:
*   FT_Data
*
* @description:
*   Read-only binary data represented as a pointer and a length.
*
* @fields:
*   pointer ::
*     The data.
*
*   length ::
*     The length of the data in bytes.
*/
FT_Data :: FT_Data_;

/**************************************************************************
*
* @functype:
*   FT_Generic_Finalizer
*
* @description:
*   Describe a function used to destroy the 'client' data of any FreeType
*   object.  See the description of the @FT_Generic type for details of
*   usage.
*
* @input:
*   The address of the FreeType object that is under finalization.  Its
*   client data is accessed through its `generic` field.
*/
FT_Generic_Finalizer :: #type (object: *void) -> void #c_call;

/**************************************************************************
*
* @struct:
*   FT_Generic
*
* @description:
*   Client applications often need to associate their own data to a
*   variety of FreeType core objects.  For example, a text layout API
*   might want to associate a glyph cache to a given size object.
*
*   Some FreeType object contains a `generic` field, of type `FT_Generic`,
*   which usage is left to client applications and font servers.
*
*   It can be used to store a pointer to client-specific data, as well as
*   the address of a 'finalizer' function, which will be called by
*   FreeType when the object is destroyed (for example, the previous
*   client example would put the address of the glyph cache destructor in
*   the `finalizer` field).
*
* @fields:
*   data ::
*     A typeless pointer to any client-specified data. This field is
*     completely ignored by the FreeType library.
*
*   finalizer ::
*     A pointer to a 'generic finalizer' function, which will be called
*     when the object is destroyed.  If this field is set to `NULL`, no
*     code will be called.
*/
FT_Generic_ :: struct {
    data:      *void;
    finalizer: FT_Generic_Finalizer;
}

/**************************************************************************
*
* @struct:
*   FT_Generic
*
* @description:
*   Client applications often need to associate their own data to a
*   variety of FreeType core objects.  For example, a text layout API
*   might want to associate a glyph cache to a given size object.
*
*   Some FreeType object contains a `generic` field, of type `FT_Generic`,
*   which usage is left to client applications and font servers.
*
*   It can be used to store a pointer to client-specific data, as well as
*   the address of a 'finalizer' function, which will be called by
*   FreeType when the object is destroyed (for example, the previous
*   client example would put the address of the glyph cache destructor in
*   the `finalizer` field).
*
* @fields:
*   data ::
*     A typeless pointer to any client-specified data. This field is
*     completely ignored by the FreeType library.
*
*   finalizer ::
*     A pointer to a 'generic finalizer' function, which will be called
*     when the object is destroyed.  If this field is set to `NULL`, no
*     code will be called.
*/
FT_Generic :: FT_Generic_;

/**************************************************************************
*
* @type:
*   FT_ListNode
*
* @description:
*    Many elements and objects in FreeType are listed through an @FT_List
*    record (see @FT_ListRec).  As its name suggests, an FT_ListNode is a
*    handle to a single list element.
*/
FT_ListNode :: *FT_ListNodeRec_;

/**************************************************************************
*
* @type:
*   FT_List
*
* @description:
*   A handle to a list record (see @FT_ListRec).
*/
FT_List :: *FT_ListRec_;

/**************************************************************************
*
* @struct:
*   FT_ListNodeRec
*
* @description:
*   A structure used to hold a single list element.
*
* @fields:
*   prev ::
*     The previous element in the list.  `NULL` if first.
*
*   next ::
*     The next element in the list.  `NULL` if last.
*
*   data ::
*     A typeless pointer to the listed object.
*/
FT_ListNodeRec_ :: struct {
    prev: FT_ListNode;
    next: FT_ListNode;
    data: *void;
}

/**************************************************************************
*
* @struct:
*   FT_ListNodeRec
*
* @description:
*   A structure used to hold a single list element.
*
* @fields:
*   prev ::
*     The previous element in the list.  `NULL` if first.
*
*   next ::
*     The next element in the list.  `NULL` if last.
*
*   data ::
*     A typeless pointer to the listed object.
*/
FT_ListNodeRec :: FT_ListNodeRec_;

/**************************************************************************
*
* @struct:
*   FT_ListRec
*
* @description:
*   A structure used to hold a simple doubly-linked list.  These are used
*   in many parts of FreeType.
*
* @fields:
*   head ::
*     The head (first element) of doubly-linked list.
*
*   tail ::
*     The tail (last element) of doubly-linked list.
*/
FT_ListRec_ :: struct {
    head: FT_ListNode;
    tail: FT_ListNode;
}

/**************************************************************************
*
* @struct:
*   FT_ListRec
*
* @description:
*   A structure used to hold a simple doubly-linked list.  These are used
*   in many parts of FreeType.
*
* @fields:
*   head ::
*     The head (first element) of doubly-linked list.
*
*   tail ::
*     The tail (last element) of doubly-linked list.
*/
FT_ListRec :: FT_ListRec_;

FT_Mod_Err :: enum u32 {
    Base     :: 0;
    Autofit  :: 0;
    BDF      :: 0;
    Bzip2    :: 0;
    Cache    :: 0;
    CFF      :: 0;
    CID      :: 0;
    Gzip     :: 0;
    LZW      :: 0;
    OTvalid  :: 0;
    PCF      :: 0;
    PFR      :: 0;
    PSaux    :: 0;
    PShinter :: 0;
    PSnames  :: 0;
    Raster   :: 0;
    SFNT     :: 0;
    Smooth   :: 0;
    TrueType :: 0;
    Type1    :: 0;
    Type42   :: 0;
    Winfonts :: 0;
    GXvalid  :: 0;
    Sdf      :: 0;

    Max      :: 1;

    FT_Mod_Err_Base     :: Base;
    FT_Mod_Err_Autofit  :: Autofit;
    FT_Mod_Err_BDF      :: BDF;
    FT_Mod_Err_Bzip2    :: Bzip2;
    FT_Mod_Err_Cache    :: Cache;
    FT_Mod_Err_CFF      :: CFF;
    FT_Mod_Err_CID      :: CID;
    FT_Mod_Err_Gzip     :: Gzip;
    FT_Mod_Err_LZW      :: LZW;
    FT_Mod_Err_OTvalid  :: OTvalid;
    FT_Mod_Err_PCF      :: PCF;
    FT_Mod_Err_PFR      :: PFR;
    FT_Mod_Err_PSaux    :: PSaux;
    FT_Mod_Err_PShinter :: PShinter;
    FT_Mod_Err_PSnames  :: PSnames;
    FT_Mod_Err_Raster   :: Raster;
    FT_Mod_Err_SFNT     :: SFNT;
    FT_Mod_Err_Smooth   :: Smooth;
    FT_Mod_Err_TrueType :: TrueType;
    FT_Mod_Err_Type1    :: Type1;
    FT_Mod_Err_Type42   :: Type42;
    FT_Mod_Err_Winfonts :: Winfonts;
    FT_Mod_Err_GXvalid  :: GXvalid;
    FT_Mod_Err_Sdf      :: Sdf;

    FT_Mod_Err_Max      :: Max;
}

FT_Err :: enum u32 {
    Ok                            :: 0;

    Cannot_Open_Resource          :: 1;

    Unknown_File_Format           :: 2;

    Invalid_File_Format           :: 3;

    Invalid_Version               :: 4;

    Lower_Module_Version          :: 5;

    Invalid_Argument              :: 6;

    Unimplemented_Feature         :: 7;

    Invalid_Table                 :: 8;

    Invalid_Offset                :: 9;

    Array_Too_Large               :: 10;

    Missing_Module                :: 11;

    Missing_Property              :: 12;

    Invalid_Glyph_Index           :: 16;

    Invalid_Character_Code        :: 17;

    Invalid_Glyph_Format          :: 18;

    Cannot_Render_Glyph           :: 19;

    Invalid_Outline               :: 20;

    Invalid_Composite             :: 21;

    Too_Many_Hints                :: 22;

    Invalid_Pixel_Size            :: 23;

    Invalid_SVG_Document          :: 24;

    Invalid_Handle                :: 32;

    Invalid_Library_Handle        :: 33;

    Invalid_Driver_Handle         :: 34;

    Invalid_Face_Handle           :: 35;

    Invalid_Size_Handle           :: 36;

    Invalid_Slot_Handle           :: 37;

    Invalid_CharMap_Handle        :: 38;

    Invalid_Cache_Handle          :: 39;

    Invalid_Stream_Handle         :: 40;

    Too_Many_Drivers              :: 48;

    Too_Many_Extensions           :: 49;

    Out_Of_Memory                 :: 64;

    Unlisted_Object               :: 65;

    Cannot_Open_Stream            :: 81;

    Invalid_Stream_Seek           :: 82;

    Invalid_Stream_Skip           :: 83;

    Invalid_Stream_Read           :: 84;

    Invalid_Stream_Operation      :: 85;

    Invalid_Frame_Operation       :: 86;

    Nested_Frame_Access           :: 87;

    Invalid_Frame_Read            :: 88;

    Raster_Uninitialized          :: 96;

    Raster_Corrupted              :: 97;

    Raster_Overflow               :: 98;

    Raster_Negative_Height        :: 99;

    Too_Many_Caches               :: 112;

    Invalid_Opcode                :: 128;

    Too_Few_Arguments             :: 129;

    Stack_Overflow                :: 130;

    Code_Overflow                 :: 131;

    Bad_Argument                  :: 132;

    Divide_By_Zero                :: 133;

    Invalid_Reference             :: 134;

    Debug_OpCode                  :: 135;

    ENDF_In_Exec_Stream           :: 136;

    Nested_DEFS                   :: 137;

    Invalid_CodeRange             :: 138;

    Execution_Too_Long            :: 139;

    Too_Many_Function_Defs        :: 140;

    Too_Many_Instruction_Defs     :: 141;

    Table_Missing                 :: 142;

    Horiz_Header_Missing          :: 143;

    Locations_Missing             :: 144;

    Name_Table_Missing            :: 145;

    CMap_Table_Missing            :: 146;

    Hmtx_Table_Missing            :: 147;

    Post_Table_Missing            :: 148;

    Invalid_Horiz_Metrics         :: 149;

    Invalid_CharMap_Format        :: 150;

    Invalid_PPem                  :: 151;

    Invalid_Vert_Metrics          :: 152;

    Could_Not_Find_Context        :: 153;

    Invalid_Post_Table_Format     :: 154;

    Invalid_Post_Table            :: 155;

    DEF_In_Glyf_Bytecode          :: 156;

    Missing_Bitmap                :: 157;

    Missing_SVG_Hooks             :: 158;

    Syntax_Error                  :: 160;

    Stack_Underflow               :: 161;

    Ignore                        :: 162;

    No_Unicode_Glyph_Name         :: 163;

    Glyph_Too_Big                 :: 164;

    Missing_Startfont_Field       :: 176;

    Missing_Font_Field            :: 177;

    Missing_Size_Field            :: 178;

    Missing_Fontboundingbox_Field :: 179;

    Missing_Chars_Field           :: 180;

    Missing_Startchar_Field       :: 181;

    Missing_Encoding_Field        :: 182;

    Missing_Bbx_Field             :: 183;

    Bbx_Too_Big                   :: 184;

    Corrupted_Font_Header         :: 185;

    Corrupted_Font_Glyphs         :: 186;

    Max                           :: 187;

    FT_Err_Ok                            :: Ok;

    FT_Err_Cannot_Open_Resource          :: Cannot_Open_Resource;

    FT_Err_Unknown_File_Format           :: Unknown_File_Format;

    FT_Err_Invalid_File_Format           :: Invalid_File_Format;

    FT_Err_Invalid_Version               :: Invalid_Version;

    FT_Err_Lower_Module_Version          :: Lower_Module_Version;

    FT_Err_Invalid_Argument              :: Invalid_Argument;

    FT_Err_Unimplemented_Feature         :: Unimplemented_Feature;

    FT_Err_Invalid_Table                 :: Invalid_Table;

    FT_Err_Invalid_Offset                :: Invalid_Offset;

    FT_Err_Array_Too_Large               :: Array_Too_Large;

    FT_Err_Missing_Module                :: Missing_Module;

    FT_Err_Missing_Property              :: Missing_Property;

    FT_Err_Invalid_Glyph_Index           :: Invalid_Glyph_Index;

    FT_Err_Invalid_Character_Code        :: Invalid_Character_Code;

    FT_Err_Invalid_Glyph_Format          :: Invalid_Glyph_Format;

    FT_Err_Cannot_Render_Glyph           :: Cannot_Render_Glyph;

    FT_Err_Invalid_Outline               :: Invalid_Outline;

    FT_Err_Invalid_Composite             :: Invalid_Composite;

    FT_Err_Too_Many_Hints                :: Too_Many_Hints;

    FT_Err_Invalid_Pixel_Size            :: Invalid_Pixel_Size;

    FT_Err_Invalid_SVG_Document          :: Invalid_SVG_Document;

    FT_Err_Invalid_Handle                :: Invalid_Handle;

    FT_Err_Invalid_Library_Handle        :: Invalid_Library_Handle;

    FT_Err_Invalid_Driver_Handle         :: Invalid_Driver_Handle;

    FT_Err_Invalid_Face_Handle           :: Invalid_Face_Handle;

    FT_Err_Invalid_Size_Handle           :: Invalid_Size_Handle;

    FT_Err_Invalid_Slot_Handle           :: Invalid_Slot_Handle;

    FT_Err_Invalid_CharMap_Handle        :: Invalid_CharMap_Handle;

    FT_Err_Invalid_Cache_Handle          :: Invalid_Cache_Handle;

    FT_Err_Invalid_Stream_Handle         :: Invalid_Stream_Handle;

    FT_Err_Too_Many_Drivers              :: Too_Many_Drivers;

    FT_Err_Too_Many_Extensions           :: Too_Many_Extensions;

    FT_Err_Out_Of_Memory                 :: Out_Of_Memory;

    FT_Err_Unlisted_Object               :: Unlisted_Object;

    FT_Err_Cannot_Open_Stream            :: Cannot_Open_Stream;

    FT_Err_Invalid_Stream_Seek           :: Invalid_Stream_Seek;

    FT_Err_Invalid_Stream_Skip           :: Invalid_Stream_Skip;

    FT_Err_Invalid_Stream_Read           :: Invalid_Stream_Read;

    FT_Err_Invalid_Stream_Operation      :: Invalid_Stream_Operation;

    FT_Err_Invalid_Frame_Operation       :: Invalid_Frame_Operation;

    FT_Err_Nested_Frame_Access           :: Nested_Frame_Access;

    FT_Err_Invalid_Frame_Read            :: Invalid_Frame_Read;

    FT_Err_Raster_Uninitialized          :: Raster_Uninitialized;

    FT_Err_Raster_Corrupted              :: Raster_Corrupted;

    FT_Err_Raster_Overflow               :: Raster_Overflow;

    FT_Err_Raster_Negative_Height        :: Raster_Negative_Height;

    FT_Err_Too_Many_Caches               :: Too_Many_Caches;

    FT_Err_Invalid_Opcode                :: Invalid_Opcode;

    FT_Err_Too_Few_Arguments             :: Too_Few_Arguments;

    FT_Err_Stack_Overflow                :: Stack_Overflow;

    FT_Err_Code_Overflow                 :: Code_Overflow;

    FT_Err_Bad_Argument                  :: Bad_Argument;

    FT_Err_Divide_By_Zero                :: Divide_By_Zero;

    FT_Err_Invalid_Reference             :: Invalid_Reference;

    FT_Err_Debug_OpCode                  :: Debug_OpCode;

    FT_Err_ENDF_In_Exec_Stream           :: ENDF_In_Exec_Stream;

    FT_Err_Nested_DEFS                   :: Nested_DEFS;

    FT_Err_Invalid_CodeRange             :: Invalid_CodeRange;

    FT_Err_Execution_Too_Long            :: Execution_Too_Long;

    FT_Err_Too_Many_Function_Defs        :: Too_Many_Function_Defs;

    FT_Err_Too_Many_Instruction_Defs     :: Too_Many_Instruction_Defs;

    FT_Err_Table_Missing                 :: Table_Missing;

    FT_Err_Horiz_Header_Missing          :: Horiz_Header_Missing;

    FT_Err_Locations_Missing             :: Locations_Missing;

    FT_Err_Name_Table_Missing            :: Name_Table_Missing;

    FT_Err_CMap_Table_Missing            :: CMap_Table_Missing;

    FT_Err_Hmtx_Table_Missing            :: Hmtx_Table_Missing;

    FT_Err_Post_Table_Missing            :: Post_Table_Missing;

    FT_Err_Invalid_Horiz_Metrics         :: Invalid_Horiz_Metrics;

    FT_Err_Invalid_CharMap_Format        :: Invalid_CharMap_Format;

    FT_Err_Invalid_PPem                  :: Invalid_PPem;

    FT_Err_Invalid_Vert_Metrics          :: Invalid_Vert_Metrics;

    FT_Err_Could_Not_Find_Context        :: Could_Not_Find_Context;

    FT_Err_Invalid_Post_Table_Format     :: Invalid_Post_Table_Format;

    FT_Err_Invalid_Post_Table            :: Invalid_Post_Table;

    FT_Err_DEF_In_Glyf_Bytecode          :: DEF_In_Glyf_Bytecode;

    FT_Err_Missing_Bitmap                :: Missing_Bitmap;

    FT_Err_Missing_SVG_Hooks             :: Missing_SVG_Hooks;

    FT_Err_Syntax_Error                  :: Syntax_Error;

    FT_Err_Stack_Underflow               :: Stack_Underflow;

    FT_Err_Ignore                        :: Ignore;

    FT_Err_No_Unicode_Glyph_Name         :: No_Unicode_Glyph_Name;

    FT_Err_Glyph_Too_Big                 :: Glyph_Too_Big;

    FT_Err_Missing_Startfont_Field       :: Missing_Startfont_Field;

    FT_Err_Missing_Font_Field            :: Missing_Font_Field;

    FT_Err_Missing_Size_Field            :: Missing_Size_Field;

    FT_Err_Missing_Fontboundingbox_Field :: Missing_Fontboundingbox_Field;

    FT_Err_Missing_Chars_Field           :: Missing_Chars_Field;

    FT_Err_Missing_Startchar_Field       :: Missing_Startchar_Field;

    FT_Err_Missing_Encoding_Field        :: Missing_Encoding_Field;

    FT_Err_Missing_Bbx_Field             :: Missing_Bbx_Field;

    FT_Err_Bbx_Too_Big                   :: Bbx_Too_Big;

    FT_Err_Corrupted_Font_Header         :: Corrupted_Font_Header;

    FT_Err_Corrupted_Font_Glyphs         :: Corrupted_Font_Glyphs;

    FT_Err_Max                           :: Max;
}

/**************************************************************************
*
* @function:
*   FT_Error_String
*
* @description:
*   Retrieve the description of a valid FreeType error code.
*
* @input:
*   error_code ::
*     A valid FreeType error code.
*
* @return:
*   A C~string or `NULL`, if any error occurred.
*
* @note:
*   FreeType has to be compiled with `FT_CONFIG_OPTION_ERROR_STRINGS` or
*   `FT_DEBUG_LEVEL_ERROR` to get meaningful descriptions.
*   'error_string' will be `NULL` otherwise.
*
*   Module identification will be ignored:
*
*   ```c
*     strcmp( FT_Error_String(  FT_Err_Unknown_File_Format ),
*             FT_Error_String( BDF_Err_Unknown_File_Format ) ) == 0;
*   ```
*/
FT_Error_String :: (error_code: FT_Error) -> *u8 #foreign freetype;

/**************************************************************************
*
* @struct:
*   FT_Glyph_Metrics
*
* @description:
*   A structure to model the metrics of a single glyph.  The values are
*   expressed in 26.6 fractional pixel format; if the flag
*   @FT_LOAD_NO_SCALE has been used while loading the glyph, values are
*   expressed in font units instead.
*
* @fields:
*   width ::
*     The glyph's width.
*
*   height ::
*     The glyph's height.
*
*   horiBearingX ::
*     Left side bearing for horizontal layout.
*
*   horiBearingY ::
*     Top side bearing for horizontal layout.
*
*   horiAdvance ::
*     Advance width for horizontal layout.
*
*   vertBearingX ::
*     Left side bearing for vertical layout.
*
*   vertBearingY ::
*     Top side bearing for vertical layout.  Larger positive values mean
*     further below the vertical glyph origin.
*
*   vertAdvance ::
*     Advance height for vertical layout.  Positive values mean the glyph
*     has a positive advance downward.
*
* @note:
*   If not disabled with @FT_LOAD_NO_HINTING, the values represent
*   dimensions of the hinted glyph (in case hinting is applicable).
*
*   Stroking a glyph with an outside border does not increase
*   `horiAdvance` or `vertAdvance`; you have to manually adjust these
*   values to account for the added width and height.
*
*   FreeType doesn't use the 'VORG' table data for CFF fonts because it
*   doesn't have an interface to quickly retrieve the glyph height.  The
*   y~coordinate of the vertical origin can be simply computed as
*   `vertBearingY + height` after loading a glyph.
*/
FT_Glyph_Metrics_ :: struct {
    width:        FT_Pos;
    height:       FT_Pos;

    horiBearingX: FT_Pos;
    horiBearingY: FT_Pos;
    horiAdvance:  FT_Pos;

    vertBearingX: FT_Pos;
    vertBearingY: FT_Pos;
    vertAdvance:  FT_Pos;
}

/**************************************************************************
*
* @struct:
*   FT_Glyph_Metrics
*
* @description:
*   A structure to model the metrics of a single glyph.  The values are
*   expressed in 26.6 fractional pixel format; if the flag
*   @FT_LOAD_NO_SCALE has been used while loading the glyph, values are
*   expressed in font units instead.
*
* @fields:
*   width ::
*     The glyph's width.
*
*   height ::
*     The glyph's height.
*
*   horiBearingX ::
*     Left side bearing for horizontal layout.
*
*   horiBearingY ::
*     Top side bearing for horizontal layout.
*
*   horiAdvance ::
*     Advance width for horizontal layout.
*
*   vertBearingX ::
*     Left side bearing for vertical layout.
*
*   vertBearingY ::
*     Top side bearing for vertical layout.  Larger positive values mean
*     further below the vertical glyph origin.
*
*   vertAdvance ::
*     Advance height for vertical layout.  Positive values mean the glyph
*     has a positive advance downward.
*
* @note:
*   If not disabled with @FT_LOAD_NO_HINTING, the values represent
*   dimensions of the hinted glyph (in case hinting is applicable).
*
*   Stroking a glyph with an outside border does not increase
*   `horiAdvance` or `vertAdvance`; you have to manually adjust these
*   values to account for the added width and height.
*
*   FreeType doesn't use the 'VORG' table data for CFF fonts because it
*   doesn't have an interface to quickly retrieve the glyph height.  The
*   y~coordinate of the vertical origin can be simply computed as
*   `vertBearingY + height` after loading a glyph.
*/
FT_Glyph_Metrics :: FT_Glyph_Metrics_;

/**************************************************************************
*
* @struct:
*   FT_Bitmap_Size
*
* @description:
*   This structure models the metrics of a bitmap strike (i.e., a set of
*   glyphs for a given point size and resolution) in a bitmap font.  It is
*   used for the `available_sizes` field of @FT_Face.
*
* @fields:
*   height ::
*     The vertical distance, in pixels, between two consecutive baselines.
*     It is always positive.
*
*   width ::
*     The average width, in pixels, of all glyphs in the strike.
*
*   size ::
*     The nominal size of the strike in 26.6 fractional points.  This
*     field is not very useful.
*
*   x_ppem ::
*     The horizontal ppem (nominal width) in 26.6 fractional pixels.
*
*   y_ppem ::
*     The vertical ppem (nominal height) in 26.6 fractional pixels.
*
* @note:
*   Windows FNT:
*     The nominal size given in a FNT font is not reliable.  If the driver
*     finds it incorrect, it sets `size` to some calculated values, and
*     `x_ppem` and `y_ppem` to the pixel width and height given in the
*     font, respectively.
*
*   TrueType embedded bitmaps:
*     `size`, `width`, and `height` values are not contained in the bitmap
*     strike itself.  They are computed from the global font parameters.
*/
FT_Bitmap_Size_ :: struct {
    height: FT_Short;
    width:  FT_Short;

    size:   FT_Pos;

    x_ppem: FT_Pos;
    y_ppem: FT_Pos;
}

/**************************************************************************
*
* @struct:
*   FT_Bitmap_Size
*
* @description:
*   This structure models the metrics of a bitmap strike (i.e., a set of
*   glyphs for a given point size and resolution) in a bitmap font.  It is
*   used for the `available_sizes` field of @FT_Face.
*
* @fields:
*   height ::
*     The vertical distance, in pixels, between two consecutive baselines.
*     It is always positive.
*
*   width ::
*     The average width, in pixels, of all glyphs in the strike.
*
*   size ::
*     The nominal size of the strike in 26.6 fractional points.  This
*     field is not very useful.
*
*   x_ppem ::
*     The horizontal ppem (nominal width) in 26.6 fractional pixels.
*
*   y_ppem ::
*     The vertical ppem (nominal height) in 26.6 fractional pixels.
*
* @note:
*   Windows FNT:
*     The nominal size given in a FNT font is not reliable.  If the driver
*     finds it incorrect, it sets `size` to some calculated values, and
*     `x_ppem` and `y_ppem` to the pixel width and height given in the
*     font, respectively.
*
*   TrueType embedded bitmaps:
*     `size`, `width`, and `height` values are not contained in the bitmap
*     strike itself.  They are computed from the global font parameters.
*/
FT_Bitmap_Size :: FT_Bitmap_Size_;

FT_LibraryRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Library
*
* @description:
*   A handle to a FreeType library instance.  Each 'library' is completely
*   independent from the others; it is the 'root' of a set of objects like
*   fonts, faces, sizes, etc.
*
*   It also embeds a memory manager (see @FT_Memory), as well as a
*   scan-line converter object (see @FT_Raster).
*
*   [Since 2.5.6] In multi-threaded applications it is easiest to use one
*   `FT_Library` object per thread.  In case this is too cumbersome, a
*   single `FT_Library` object across threads is possible also, as long as
*   a mutex lock is used around @FT_New_Face and @FT_Done_Face.
*
* @note:
*   Library objects are normally created by @FT_Init_FreeType, and
*   destroyed with @FT_Done_FreeType.  If you need reference-counting
*   (cf. @FT_Reference_Library), use @FT_New_Library and @FT_Done_Library.
*/
FT_Library :: *FT_LibraryRec_;

FT_ModuleRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Module
*
* @description:
*   A handle to a given FreeType module object.  A module can be a font
*   driver, a renderer, or anything else that provides services to the
*   former.
*/
FT_Module :: *FT_ModuleRec_;

FT_DriverRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Driver
*
* @description:
*   A handle to a given FreeType font driver object.  A font driver is a
*   module capable of creating faces from font files.
*/
FT_Driver :: *FT_DriverRec_;

FT_RendererRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Renderer
*
* @description:
*   A handle to a given FreeType renderer.  A renderer is a module in
*   charge of converting a glyph's outline image to a bitmap.  It supports
*   a single glyph image format, and one or more target surface depths.
*/
FT_Renderer :: *FT_RendererRec_;

/**************************************************************************
*
* @type:
*   FT_Face
*
* @description:
*   A handle to a typographic face object.  A face object models a given
*   typeface, in a given style.
*
* @note:
*   A face object also owns a single @FT_GlyphSlot object, as well as one
*   or more @FT_Size objects.
*
*   Use @FT_New_Face or @FT_Open_Face to create a new face object from a
*   given filepath or a custom input stream.
*
*   Use @FT_Done_Face to destroy it (along with its slot and sizes).
*
*   An `FT_Face` object can only be safely used from one thread at a time.
*   Similarly, creation and destruction of `FT_Face` with the same
*   @FT_Library object can only be done from one thread at a time.  On the
*   other hand, functions like @FT_Load_Glyph and its siblings are
*   thread-safe and do not need the lock to be held as long as the same
*   `FT_Face` object is not used from multiple threads at the same time.
*
* @also:
*   See @FT_FaceRec for the publicly accessible fields of a given face
*   object.
*/
FT_Face :: *FT_FaceRec_;

/**************************************************************************
*
* @type:
*   FT_Size
*
* @description:
*   A handle to an object that models a face scaled to a given character
*   size.
*
* @note:
*   An @FT_Face has one _active_ `FT_Size` object that is used by
*   functions like @FT_Load_Glyph to determine the scaling transformation
*   that in turn is used to load and hint glyphs and metrics.
*
*   A newly created `FT_Size` object contains only meaningless zero values.
*   You must use @FT_Set_Char_Size, @FT_Set_Pixel_Sizes, @FT_Request_Size
*   or even @FT_Select_Size to change the content (i.e., the scaling
*   values) of the active `FT_Size`.  Otherwise, the scaling and hinting
*   will not be performed.
*
*   You can use @FT_New_Size to create additional size objects for a given
*   @FT_Face, but they won't be used by other functions until you activate
*   it through @FT_Activate_Size.  Only one size can be activated at any
*   given time per face.
*
* @also:
*   See @FT_SizeRec for the publicly accessible fields of a given size
*   object.
*/
FT_Size :: *FT_SizeRec_;

/**************************************************************************
*
* @type:
*   FT_GlyphSlot
*
* @description:
*   A handle to a given 'glyph slot'.  A slot is a container that can hold
*   any of the glyphs contained in its parent face.
*
*   In other words, each time you call @FT_Load_Glyph or @FT_Load_Char,
*   the slot's content is erased by the new glyph data, i.e., the glyph's
*   metrics, its image (bitmap or outline), and other control information.
*
* @also:
*   See @FT_GlyphSlotRec for the publicly accessible glyph fields.
*/
FT_GlyphSlot :: *FT_GlyphSlotRec_;

/**************************************************************************
*
* @type:
*   FT_CharMap
*
* @description:
*   A handle to a character map (usually abbreviated to 'charmap').  A
*   charmap is used to translate character codes in a given encoding into
*   glyph indexes for its parent's face.  Some font formats may provide
*   several charmaps per font.
*
*   Each face object owns zero or more charmaps, but only one of them can
*   be 'active', providing the data used by @FT_Get_Char_Index or
*   @FT_Load_Char.
*
*   The list of available charmaps in a face is available through the
*   `face->num_charmaps` and `face->charmaps` fields of @FT_FaceRec.
*
*   The currently active charmap is available as `face->charmap`.  You
*   should call @FT_Set_Charmap to change it.
*
* @note:
*   When a new face is created (either through @FT_New_Face or
*   @FT_Open_Face), the library looks for a Unicode charmap within the
*   list and automatically activates it.  If there is no Unicode charmap,
*   FreeType doesn't set an 'active' charmap.
*
* @also:
*   See @FT_CharMapRec for the publicly accessible fields of a given
*   character map.
*/
FT_CharMap :: *FT_CharMapRec_;

/**************************************************************************
*
* @enum:
*   FT_Encoding
*
* @description:
*   An enumeration to specify character sets supported by charmaps.  Used
*   in the @FT_Select_Charmap API function.
*
* @note:
*   Despite the name, this enumeration lists specific character
*   repertoires (i.e., charsets), and not text encoding methods (e.g.,
*   UTF-8, UTF-16, etc.).
*
*   Other encodings might be defined in the future.
*
* @values:
*   FT_ENCODING_NONE ::
*     The encoding value~0 is reserved for all formats except BDF, PCF,
*     and Windows FNT; see below for more information.
*
*   FT_ENCODING_UNICODE ::
*     The Unicode character set.  This value covers all versions of the
*     Unicode repertoire, including ASCII and Latin-1.  Most fonts include
*     a Unicode charmap, but not all of them.
*
*     For example, if you want to access Unicode value U+1F028 (and the
*     font contains it), use value 0x1F028 as the input value for
*     @FT_Get_Char_Index.
*
*   FT_ENCODING_MS_SYMBOL ::
*     Microsoft Symbol encoding, used to encode mathematical symbols and
*     wingdings.  For more information, see
*     'https://learn.microsoft.com/typography/opentype/spec/recom#non-standard-symbol-fonts',
*     'http://www.kostis.net/charsets/symbol.htm', and
*     'http://www.kostis.net/charsets/wingding.htm'.
*
*     This encoding uses character codes from the PUA (Private Unicode
*     Area) in the range U+F020-U+F0FF.
*
*   FT_ENCODING_SJIS ::
*     Shift JIS encoding for Japanese.  More info at
*     'https://en.wikipedia.org/wiki/Shift_JIS'.  See note on multi-byte
*     encodings below.
*
*   FT_ENCODING_PRC ::
*     Corresponds to encoding systems mainly for Simplified Chinese as
*     used in People's Republic of China (PRC).  The encoding layout is
*     based on GB~2312 and its supersets GBK and GB~18030.
*
*   FT_ENCODING_BIG5 ::
*     Corresponds to an encoding system for Traditional Chinese as used in
*     Taiwan and Hong Kong.
*
*   FT_ENCODING_WANSUNG ::
*     Corresponds to the Korean encoding system known as Extended Wansung
*     (MS Windows code page 949).  For more information see
*     'https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit949.txt'.
*
*   FT_ENCODING_JOHAB ::
*     The Korean standard character set (KS~C 5601-1992), which
*     corresponds to MS Windows code page 1361.  This character set
*     includes all possible Hangul character combinations.
*
*   FT_ENCODING_ADOBE_LATIN_1 ::
*     Corresponds to a Latin-1 encoding as defined in a Type~1 PostScript
*     font.  It is limited to 256 character codes.
*
*   FT_ENCODING_ADOBE_STANDARD ::
*     Adobe Standard encoding, as found in Type~1, CFF, and OpenType/CFF
*     fonts.  It is limited to 256 character codes.
*
*   FT_ENCODING_ADOBE_EXPERT ::
*     Adobe Expert encoding, as found in Type~1, CFF, and OpenType/CFF
*     fonts.  It is limited to 256 character codes.
*
*   FT_ENCODING_ADOBE_CUSTOM ::
*     Corresponds to a custom encoding, as found in Type~1, CFF, and
*     OpenType/CFF fonts.  It is limited to 256 character codes.
*
*   FT_ENCODING_APPLE_ROMAN ::
*     Apple roman encoding.  Many TrueType and OpenType fonts contain a
*     charmap for this 8-bit encoding, since older versions of Mac OS are
*     able to use it.
*
*   FT_ENCODING_OLD_LATIN_2 ::
*     This value is deprecated and was neither used nor reported by
*     FreeType.  Don't use or test for it.
*
*   FT_ENCODING_MS_SJIS ::
*     Same as FT_ENCODING_SJIS.  Deprecated.
*
*   FT_ENCODING_MS_GB2312 ::
*     Same as FT_ENCODING_PRC.  Deprecated.
*
*   FT_ENCODING_MS_BIG5 ::
*     Same as FT_ENCODING_BIG5.  Deprecated.
*
*   FT_ENCODING_MS_WANSUNG ::
*     Same as FT_ENCODING_WANSUNG.  Deprecated.
*
*   FT_ENCODING_MS_JOHAB ::
*     Same as FT_ENCODING_JOHAB.  Deprecated.
*
* @note:
*   When loading a font, FreeType makes a Unicode charmap active if
*   possible (either if the font provides such a charmap, or if FreeType
*   can synthesize one from PostScript glyph name dictionaries; in either
*   case, the charmap is tagged with `FT_ENCODING_UNICODE`).  If such a
*   charmap is synthesized, it is placed at the first position of the
*   charmap array.
*
*   All other encodings are considered legacy and tagged only if
*   explicitly defined in the font file.  Otherwise, `FT_ENCODING_NONE` is
*   used.
*
*   `FT_ENCODING_NONE` is set by the BDF and PCF drivers if the charmap is
*   neither Unicode nor ISO-8859-1 (otherwise it is set to
*   `FT_ENCODING_UNICODE`).  Use @FT_Get_BDF_Charset_ID to find out which
*   encoding is really present.  If, for example, the `cs_registry` field
*   is 'KOI8' and the `cs_encoding` field is 'R', the font is encoded in
*   KOI8-R.
*
*   `FT_ENCODING_NONE` is always set (with a single exception) by the
*   winfonts driver.  Use @FT_Get_WinFNT_Header and examine the `charset`
*   field of the @FT_WinFNT_HeaderRec structure to find out which encoding
*   is really present.  For example, @FT_WinFNT_ID_CP1251 (204) means
*   Windows code page 1251 (for Russian).
*
*   `FT_ENCODING_NONE` is set if `platform_id` is @TT_PLATFORM_MACINTOSH
*   and `encoding_id` is not `TT_MAC_ID_ROMAN` (otherwise it is set to
*   `FT_ENCODING_APPLE_ROMAN`).
*
*   If `platform_id` is @TT_PLATFORM_MACINTOSH, use the function
*   @FT_Get_CMap_Language_ID to query the Mac language ID that may be
*   needed to be able to distinguish Apple encoding variants.  See
*
*     https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/Readme.txt
*
*   to get an idea how to do that.  Basically, if the language ID is~0,
*   don't use it, otherwise subtract 1 from the language ID.  Then examine
*   `encoding_id`.  If, for example, `encoding_id` is `TT_MAC_ID_ROMAN`
*   and the language ID (minus~1) is `TT_MAC_LANGID_GREEK`, it is the
*   Greek encoding, not Roman.  `TT_MAC_ID_ARABIC` with
*   `TT_MAC_LANGID_FARSI` means the Farsi variant of the Arabic encoding.
*/
FT_Encoding_ :: enum u32 {
    NONE           :: 0;

    MS_SYMBOL      :: 1937337698;
    UNICODE        :: 1970170211;

    SJIS           :: 1936353651;
    PRC            :: 1734484000;
    BIG5           :: 1651074869;
    WANSUNG        :: 2002873971;
    JOHAB          :: 1785686113;

    GB2312         :: 1734484000;
    MS_SJIS        :: 1936353651;
    MS_GB2312      :: 1734484000;
    MS_BIG5        :: 1651074869;
    MS_WANSUNG     :: 2002873971;
    MS_JOHAB       :: 1785686113;

    ADOBE_STANDARD :: 1094995778;
    ADOBE_EXPERT   :: 1094992453;
    ADOBE_CUSTOM   :: 1094992451;
    ADOBE_LATIN_1  :: 1818326065;

    OLD_LATIN_2    :: 1818326066;

    APPLE_ROMAN    :: 1634889070;

    FT_ENCODING_NONE           :: NONE;

    FT_ENCODING_MS_SYMBOL      :: MS_SYMBOL;
    FT_ENCODING_UNICODE        :: UNICODE;

    FT_ENCODING_SJIS           :: SJIS;
    FT_ENCODING_PRC            :: PRC;
    FT_ENCODING_BIG5           :: BIG5;
    FT_ENCODING_WANSUNG        :: WANSUNG;
    FT_ENCODING_JOHAB          :: JOHAB;

    FT_ENCODING_GB2312         :: GB2312;
    FT_ENCODING_MS_SJIS        :: MS_SJIS;
    FT_ENCODING_MS_GB2312      :: MS_GB2312;
    FT_ENCODING_MS_BIG5        :: MS_BIG5;
    FT_ENCODING_MS_WANSUNG     :: MS_WANSUNG;
    FT_ENCODING_MS_JOHAB       :: MS_JOHAB;

    FT_ENCODING_ADOBE_STANDARD :: ADOBE_STANDARD;
    FT_ENCODING_ADOBE_EXPERT   :: ADOBE_EXPERT;
    FT_ENCODING_ADOBE_CUSTOM   :: ADOBE_CUSTOM;
    FT_ENCODING_ADOBE_LATIN_1  :: ADOBE_LATIN_1;

    FT_ENCODING_OLD_LATIN_2    :: OLD_LATIN_2;

    FT_ENCODING_APPLE_ROMAN    :: APPLE_ROMAN;
}

/**************************************************************************
*
* @enum:
*   FT_Encoding
*
* @description:
*   An enumeration to specify character sets supported by charmaps.  Used
*   in the @FT_Select_Charmap API function.
*
* @note:
*   Despite the name, this enumeration lists specific character
*   repertoires (i.e., charsets), and not text encoding methods (e.g.,
*   UTF-8, UTF-16, etc.).
*
*   Other encodings might be defined in the future.
*
* @values:
*   FT_ENCODING_NONE ::
*     The encoding value~0 is reserved for all formats except BDF, PCF,
*     and Windows FNT; see below for more information.
*
*   FT_ENCODING_UNICODE ::
*     The Unicode character set.  This value covers all versions of the
*     Unicode repertoire, including ASCII and Latin-1.  Most fonts include
*     a Unicode charmap, but not all of them.
*
*     For example, if you want to access Unicode value U+1F028 (and the
*     font contains it), use value 0x1F028 as the input value for
*     @FT_Get_Char_Index.
*
*   FT_ENCODING_MS_SYMBOL ::
*     Microsoft Symbol encoding, used to encode mathematical symbols and
*     wingdings.  For more information, see
*     'https://learn.microsoft.com/typography/opentype/spec/recom#non-standard-symbol-fonts',
*     'http://www.kostis.net/charsets/symbol.htm', and
*     'http://www.kostis.net/charsets/wingding.htm'.
*
*     This encoding uses character codes from the PUA (Private Unicode
*     Area) in the range U+F020-U+F0FF.
*
*   FT_ENCODING_SJIS ::
*     Shift JIS encoding for Japanese.  More info at
*     'https://en.wikipedia.org/wiki/Shift_JIS'.  See note on multi-byte
*     encodings below.
*
*   FT_ENCODING_PRC ::
*     Corresponds to encoding systems mainly for Simplified Chinese as
*     used in People's Republic of China (PRC).  The encoding layout is
*     based on GB~2312 and its supersets GBK and GB~18030.
*
*   FT_ENCODING_BIG5 ::
*     Corresponds to an encoding system for Traditional Chinese as used in
*     Taiwan and Hong Kong.
*
*   FT_ENCODING_WANSUNG ::
*     Corresponds to the Korean encoding system known as Extended Wansung
*     (MS Windows code page 949).  For more information see
*     'https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit949.txt'.
*
*   FT_ENCODING_JOHAB ::
*     The Korean standard character set (KS~C 5601-1992), which
*     corresponds to MS Windows code page 1361.  This character set
*     includes all possible Hangul character combinations.
*
*   FT_ENCODING_ADOBE_LATIN_1 ::
*     Corresponds to a Latin-1 encoding as defined in a Type~1 PostScript
*     font.  It is limited to 256 character codes.
*
*   FT_ENCODING_ADOBE_STANDARD ::
*     Adobe Standard encoding, as found in Type~1, CFF, and OpenType/CFF
*     fonts.  It is limited to 256 character codes.
*
*   FT_ENCODING_ADOBE_EXPERT ::
*     Adobe Expert encoding, as found in Type~1, CFF, and OpenType/CFF
*     fonts.  It is limited to 256 character codes.
*
*   FT_ENCODING_ADOBE_CUSTOM ::
*     Corresponds to a custom encoding, as found in Type~1, CFF, and
*     OpenType/CFF fonts.  It is limited to 256 character codes.
*
*   FT_ENCODING_APPLE_ROMAN ::
*     Apple roman encoding.  Many TrueType and OpenType fonts contain a
*     charmap for this 8-bit encoding, since older versions of Mac OS are
*     able to use it.
*
*   FT_ENCODING_OLD_LATIN_2 ::
*     This value is deprecated and was neither used nor reported by
*     FreeType.  Don't use or test for it.
*
*   FT_ENCODING_MS_SJIS ::
*     Same as FT_ENCODING_SJIS.  Deprecated.
*
*   FT_ENCODING_MS_GB2312 ::
*     Same as FT_ENCODING_PRC.  Deprecated.
*
*   FT_ENCODING_MS_BIG5 ::
*     Same as FT_ENCODING_BIG5.  Deprecated.
*
*   FT_ENCODING_MS_WANSUNG ::
*     Same as FT_ENCODING_WANSUNG.  Deprecated.
*
*   FT_ENCODING_MS_JOHAB ::
*     Same as FT_ENCODING_JOHAB.  Deprecated.
*
* @note:
*   When loading a font, FreeType makes a Unicode charmap active if
*   possible (either if the font provides such a charmap, or if FreeType
*   can synthesize one from PostScript glyph name dictionaries; in either
*   case, the charmap is tagged with `FT_ENCODING_UNICODE`).  If such a
*   charmap is synthesized, it is placed at the first position of the
*   charmap array.
*
*   All other encodings are considered legacy and tagged only if
*   explicitly defined in the font file.  Otherwise, `FT_ENCODING_NONE` is
*   used.
*
*   `FT_ENCODING_NONE` is set by the BDF and PCF drivers if the charmap is
*   neither Unicode nor ISO-8859-1 (otherwise it is set to
*   `FT_ENCODING_UNICODE`).  Use @FT_Get_BDF_Charset_ID to find out which
*   encoding is really present.  If, for example, the `cs_registry` field
*   is 'KOI8' and the `cs_encoding` field is 'R', the font is encoded in
*   KOI8-R.
*
*   `FT_ENCODING_NONE` is always set (with a single exception) by the
*   winfonts driver.  Use @FT_Get_WinFNT_Header and examine the `charset`
*   field of the @FT_WinFNT_HeaderRec structure to find out which encoding
*   is really present.  For example, @FT_WinFNT_ID_CP1251 (204) means
*   Windows code page 1251 (for Russian).
*
*   `FT_ENCODING_NONE` is set if `platform_id` is @TT_PLATFORM_MACINTOSH
*   and `encoding_id` is not `TT_MAC_ID_ROMAN` (otherwise it is set to
*   `FT_ENCODING_APPLE_ROMAN`).
*
*   If `platform_id` is @TT_PLATFORM_MACINTOSH, use the function
*   @FT_Get_CMap_Language_ID to query the Mac language ID that may be
*   needed to be able to distinguish Apple encoding variants.  See
*
*     https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/Readme.txt
*
*   to get an idea how to do that.  Basically, if the language ID is~0,
*   don't use it, otherwise subtract 1 from the language ID.  Then examine
*   `encoding_id`.  If, for example, `encoding_id` is `TT_MAC_ID_ROMAN`
*   and the language ID (minus~1) is `TT_MAC_LANGID_GREEK`, it is the
*   Greek encoding, not Roman.  `TT_MAC_ID_ARABIC` with
*   `TT_MAC_LANGID_FARSI` means the Farsi variant of the Arabic encoding.
*/
FT_Encoding :: FT_Encoding_;

/**************************************************************************
*
* @struct:
*   FT_CharMapRec
*
* @description:
*   The base charmap structure.
*
* @fields:
*   face ::
*     A handle to the parent face object.
*
*   encoding ::
*     An @FT_Encoding tag identifying the charmap.  Use this with
*     @FT_Select_Charmap.
*
*   platform_id ::
*     An ID number describing the platform for the following encoding ID.
*     This comes directly from the TrueType specification and gets
*     emulated for other formats.
*
*   encoding_id ::
*     A platform-specific encoding number.  This also comes from the
*     TrueType specification and gets emulated similarly.
*/
FT_CharMapRec_ :: struct {
    face:        FT_Face;
    encoding:    FT_Encoding;
    platform_id: FT_UShort;
    encoding_id: FT_UShort;
}

/**************************************************************************
*
* @struct:
*   FT_CharMapRec
*
* @description:
*   The base charmap structure.
*
* @fields:
*   face ::
*     A handle to the parent face object.
*
*   encoding ::
*     An @FT_Encoding tag identifying the charmap.  Use this with
*     @FT_Select_Charmap.
*
*   platform_id ::
*     An ID number describing the platform for the following encoding ID.
*     This comes directly from the TrueType specification and gets
*     emulated for other formats.
*
*   encoding_id ::
*     A platform-specific encoding number.  This also comes from the
*     TrueType specification and gets emulated similarly.
*/
FT_CharMapRec :: FT_CharMapRec_;

FT_Face_InternalRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Face_Internal
*
* @description:
*   An opaque handle to an `FT_Face_InternalRec` structure that models the
*   private data of a given @FT_Face object.
*
*   This structure might change between releases of FreeType~2 and is not
*   generally available to client applications.
*/
FT_Face_Internal :: *FT_Face_InternalRec_;

/**************************************************************************
*
* @struct:
*   FT_FaceRec
*
* @description:
*   FreeType root face class structure.  A face object models a typeface
*   in a font file.
*
* @fields:
*   num_faces ::
*     The number of faces in the font file.  Some font formats can have
*     multiple faces in a single font file.
*
*   face_index ::
*     This field holds two different values.  Bits 0-15 are the index of
*     the face in the font file (starting with value~0).  They are set
*     to~0 if there is only one face in the font file.
*
*     [Since 2.6.1] Bits 16-30 are relevant to TrueType GX and OpenType
*     Font Variations only, holding the named instance index for the
*     current face index (starting with value~1; value~0 indicates font
*     access without a named instance).  For non-variation fonts, bits
*     16-30 are ignored.  If we have the third named instance of face~4,
*     say, `face_index` is set to 0x00030004.
*
*     Bit 31 is always zero (that is, `face_index` is always a positive
*     value).
*
*     [Since 2.9] Changing the design coordinates with
*     @FT_Set_Var_Design_Coordinates or @FT_Set_Var_Blend_Coordinates does
*     not influence the named instance index value (only
*     @FT_Set_Named_Instance does that).
*
*   face_flags ::
*     A set of bit flags that give important information about the face;
*     see @FT_FACE_FLAG_XXX for the details.
*
*   style_flags ::
*     The lower 16~bits contain a set of bit flags indicating the style of
*     the face; see @FT_STYLE_FLAG_XXX for the details.
*
*     [Since 2.6.1] Bits 16-30 hold the number of named instances
*     available for the current face if we have a TrueType GX or OpenType
*     Font Variation.  Bit 31 is always zero (that is, `style_flags` is
*     always a positive value).  Note that a variation font has always at
*     least one named instance, namely the default instance.
*
*   num_glyphs ::
*     The number of glyphs in the face.  If the face is scalable and has
*     sbits (see `num_fixed_sizes`), it is set to the number of outline
*     glyphs.
*
*     For CID-keyed fonts (not in an SFNT wrapper) this value gives the
*     highest CID used in the font.
*
*   family_name ::
*     The face's family name.  This is an ASCII string, usually in
*     English, that describes the typeface's family (like 'Times New
*     Roman', 'Bodoni', 'Garamond', etc).  This is a least common
*     denominator used to list fonts.  Some formats (TrueType & OpenType)
*     provide localized and Unicode versions of this string.  Applications
*     should use the format-specific interface to access them.  Can be
*     `NULL` (e.g., in fonts embedded in a PDF file).
*
*     In case the font doesn't provide a specific family name entry,
*     FreeType tries to synthesize one, deriving it from other name
*     entries.
*
*   style_name ::
*     The face's style name.  This is an ASCII string, usually in English,
*     that describes the typeface's style (like 'Italic', 'Bold',
*     'Condensed', etc).  Not all font formats provide a style name, so
*     this field is optional, and can be set to `NULL`.  As for
*     `family_name`, some formats provide localized and Unicode versions
*     of this string.  Applications should use the format-specific
*     interface to access them.
*
*   num_fixed_sizes ::
*     The number of bitmap strikes in the face.  Even if the face is
*     scalable, there might still be bitmap strikes, which are called
*     'sbits' in that case.
*
*   available_sizes ::
*     An array of @FT_Bitmap_Size for all bitmap strikes in the face.  It
*     is set to `NULL` if there is no bitmap strike.
*
*     Note that FreeType tries to sanitize the strike data since they are
*     sometimes sloppy or incorrect, but this can easily fail.
*
*   num_charmaps ::
*     The number of charmaps in the face.
*
*   charmaps ::
*     An array of the charmaps of the face.
*
*   generic ::
*     A field reserved for client uses.  See the @FT_Generic type
*     description.
*
*   bbox ::
*     The font bounding box.  Coordinates are expressed in font units (see
*     `units_per_EM`).  The box is large enough to contain any glyph from
*     the font.  Thus, `bbox.yMax` can be seen as the 'maximum ascender',
*     and `bbox.yMin` as the 'minimum descender'.  Only relevant for
*     scalable formats.
*
*     Note that the bounding box might be off by (at least) one pixel for
*     hinted fonts.  See @FT_Size_Metrics for further discussion.
*
*     Note that the bounding box does not vary in OpenType Font Variations
*     and should only be used in relation to the default instance.
*
*   units_per_EM ::
*     The number of font units per EM square for this face.  This is
*     typically 2048 for TrueType fonts, and 1000 for Type~1 fonts.  Only
*     relevant for scalable formats.
*
*   ascender ::
*     The typographic ascender of the face, expressed in font units.  For
*     font formats not having this information, it is set to `bbox.yMax`.
*     Only relevant for scalable formats.
*
*   descender ::
*     The typographic descender of the face, expressed in font units.  For
*     font formats not having this information, it is set to `bbox.yMin`.
*     Note that this field is negative for values below the baseline.
*     Only relevant for scalable formats.
*
*   height ::
*     This value is the vertical distance between two consecutive
*     baselines, expressed in font units.  It is always positive.  Only
*     relevant for scalable formats.
*
*     If you want the global glyph height, use `ascender - descender`.
*
*   max_advance_width ::
*     The maximum advance width, in font units, for all glyphs in this
*     face.  This can be used to make word wrapping computations faster.
*     Only relevant for scalable formats.
*
*   max_advance_height ::
*     The maximum advance height, in font units, for all glyphs in this
*     face.  This is only relevant for vertical layouts, and is set to
*     `height` for fonts that do not provide vertical metrics.  Only
*     relevant for scalable formats.
*
*   underline_position ::
*     The position, in font units, of the underline line for this face.
*     It is the center of the underlining stem.  Only relevant for
*     scalable formats.
*
*   underline_thickness ::
*     The thickness, in font units, of the underline for this face.  Only
*     relevant for scalable formats.
*
*   glyph ::
*     The face's associated glyph slot(s).
*
*   size ::
*     The current active size for this face.
*
*   charmap ::
*     The current active charmap for this face.
*
* @note:
*   Fields may be changed after a call to @FT_Attach_File or
*   @FT_Attach_Stream.
*
*   For OpenType Font Variations, the values of the following fields can
*   change after a call to @FT_Set_Var_Design_Coordinates (and friends) if
*   the font contains an 'MVAR' table: `ascender`, `descender`, `height`,
*   `underline_position`, and `underline_thickness`.
*
*   Especially for TrueType fonts see also the documentation for
*   @FT_Size_Metrics.
*/
FT_FaceRec_ :: struct {
    num_faces:           FT_Long;
    face_index:          FT_Long;

    face_flags:          FT_Long;
    style_flags:         FT_Long;

    num_glyphs:          FT_Long;

    family_name:         *FT_String;
    style_name:          *FT_String;

    num_fixed_sizes:     FT_Int;
    available_sizes:     *FT_Bitmap_Size;

    num_charmaps:        FT_Int;
    charmaps:            *FT_CharMap;

    generic:             FT_Generic;

    /* The following member variables (down to `underline_thickness`) */
    /* are only relevant to scalable outlines; cf. @FT_Bitmap_Size    */
    /* for bitmap fonts.                                              */
    bbox:                FT_BBox;

    units_per_EM:        FT_UShort;
    ascender:            FT_Short;
    descender:           FT_Short;
    height:              FT_Short;

    max_advance_width:   FT_Short;
    max_advance_height:  FT_Short;

    underline_position:  FT_Short;
    underline_thickness: FT_Short;

    glyph:               FT_GlyphSlot;
    size:                FT_Size;
    charmap:             FT_CharMap;

    /* private fields, internal to FreeType */
    driver:              FT_Driver;
    memory:              FT_Memory;
    stream:              FT_Stream;

    sizes_list:          FT_ListRec;

    autohint:            FT_Generic; /* face-specific auto-hinter data */
    extensions:          *void; /* unused                         */

    internal:            FT_Face_Internal;
}

/**************************************************************************
*
* @struct:
*   FT_FaceRec
*
* @description:
*   FreeType root face class structure.  A face object models a typeface
*   in a font file.
*
* @fields:
*   num_faces ::
*     The number of faces in the font file.  Some font formats can have
*     multiple faces in a single font file.
*
*   face_index ::
*     This field holds two different values.  Bits 0-15 are the index of
*     the face in the font file (starting with value~0).  They are set
*     to~0 if there is only one face in the font file.
*
*     [Since 2.6.1] Bits 16-30 are relevant to TrueType GX and OpenType
*     Font Variations only, holding the named instance index for the
*     current face index (starting with value~1; value~0 indicates font
*     access without a named instance).  For non-variation fonts, bits
*     16-30 are ignored.  If we have the third named instance of face~4,
*     say, `face_index` is set to 0x00030004.
*
*     Bit 31 is always zero (that is, `face_index` is always a positive
*     value).
*
*     [Since 2.9] Changing the design coordinates with
*     @FT_Set_Var_Design_Coordinates or @FT_Set_Var_Blend_Coordinates does
*     not influence the named instance index value (only
*     @FT_Set_Named_Instance does that).
*
*   face_flags ::
*     A set of bit flags that give important information about the face;
*     see @FT_FACE_FLAG_XXX for the details.
*
*   style_flags ::
*     The lower 16~bits contain a set of bit flags indicating the style of
*     the face; see @FT_STYLE_FLAG_XXX for the details.
*
*     [Since 2.6.1] Bits 16-30 hold the number of named instances
*     available for the current face if we have a TrueType GX or OpenType
*     Font Variation.  Bit 31 is always zero (that is, `style_flags` is
*     always a positive value).  Note that a variation font has always at
*     least one named instance, namely the default instance.
*
*   num_glyphs ::
*     The number of glyphs in the face.  If the face is scalable and has
*     sbits (see `num_fixed_sizes`), it is set to the number of outline
*     glyphs.
*
*     For CID-keyed fonts (not in an SFNT wrapper) this value gives the
*     highest CID used in the font.
*
*   family_name ::
*     The face's family name.  This is an ASCII string, usually in
*     English, that describes the typeface's family (like 'Times New
*     Roman', 'Bodoni', 'Garamond', etc).  This is a least common
*     denominator used to list fonts.  Some formats (TrueType & OpenType)
*     provide localized and Unicode versions of this string.  Applications
*     should use the format-specific interface to access them.  Can be
*     `NULL` (e.g., in fonts embedded in a PDF file).
*
*     In case the font doesn't provide a specific family name entry,
*     FreeType tries to synthesize one, deriving it from other name
*     entries.
*
*   style_name ::
*     The face's style name.  This is an ASCII string, usually in English,
*     that describes the typeface's style (like 'Italic', 'Bold',
*     'Condensed', etc).  Not all font formats provide a style name, so
*     this field is optional, and can be set to `NULL`.  As for
*     `family_name`, some formats provide localized and Unicode versions
*     of this string.  Applications should use the format-specific
*     interface to access them.
*
*   num_fixed_sizes ::
*     The number of bitmap strikes in the face.  Even if the face is
*     scalable, there might still be bitmap strikes, which are called
*     'sbits' in that case.
*
*   available_sizes ::
*     An array of @FT_Bitmap_Size for all bitmap strikes in the face.  It
*     is set to `NULL` if there is no bitmap strike.
*
*     Note that FreeType tries to sanitize the strike data since they are
*     sometimes sloppy or incorrect, but this can easily fail.
*
*   num_charmaps ::
*     The number of charmaps in the face.
*
*   charmaps ::
*     An array of the charmaps of the face.
*
*   generic ::
*     A field reserved for client uses.  See the @FT_Generic type
*     description.
*
*   bbox ::
*     The font bounding box.  Coordinates are expressed in font units (see
*     `units_per_EM`).  The box is large enough to contain any glyph from
*     the font.  Thus, `bbox.yMax` can be seen as the 'maximum ascender',
*     and `bbox.yMin` as the 'minimum descender'.  Only relevant for
*     scalable formats.
*
*     Note that the bounding box might be off by (at least) one pixel for
*     hinted fonts.  See @FT_Size_Metrics for further discussion.
*
*     Note that the bounding box does not vary in OpenType Font Variations
*     and should only be used in relation to the default instance.
*
*   units_per_EM ::
*     The number of font units per EM square for this face.  This is
*     typically 2048 for TrueType fonts, and 1000 for Type~1 fonts.  Only
*     relevant for scalable formats.
*
*   ascender ::
*     The typographic ascender of the face, expressed in font units.  For
*     font formats not having this information, it is set to `bbox.yMax`.
*     Only relevant for scalable formats.
*
*   descender ::
*     The typographic descender of the face, expressed in font units.  For
*     font formats not having this information, it is set to `bbox.yMin`.
*     Note that this field is negative for values below the baseline.
*     Only relevant for scalable formats.
*
*   height ::
*     This value is the vertical distance between two consecutive
*     baselines, expressed in font units.  It is always positive.  Only
*     relevant for scalable formats.
*
*     If you want the global glyph height, use `ascender - descender`.
*
*   max_advance_width ::
*     The maximum advance width, in font units, for all glyphs in this
*     face.  This can be used to make word wrapping computations faster.
*     Only relevant for scalable formats.
*
*   max_advance_height ::
*     The maximum advance height, in font units, for all glyphs in this
*     face.  This is only relevant for vertical layouts, and is set to
*     `height` for fonts that do not provide vertical metrics.  Only
*     relevant for scalable formats.
*
*   underline_position ::
*     The position, in font units, of the underline line for this face.
*     It is the center of the underlining stem.  Only relevant for
*     scalable formats.
*
*   underline_thickness ::
*     The thickness, in font units, of the underline for this face.  Only
*     relevant for scalable formats.
*
*   glyph ::
*     The face's associated glyph slot(s).
*
*   size ::
*     The current active size for this face.
*
*   charmap ::
*     The current active charmap for this face.
*
* @note:
*   Fields may be changed after a call to @FT_Attach_File or
*   @FT_Attach_Stream.
*
*   For OpenType Font Variations, the values of the following fields can
*   change after a call to @FT_Set_Var_Design_Coordinates (and friends) if
*   the font contains an 'MVAR' table: `ascender`, `descender`, `height`,
*   `underline_position`, and `underline_thickness`.
*
*   Especially for TrueType fonts see also the documentation for
*   @FT_Size_Metrics.
*/
FT_FaceRec :: FT_FaceRec_;

FT_Size_InternalRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Size_Internal
*
* @description:
*   An opaque handle to an `FT_Size_InternalRec` structure, used to model
*   private data of a given @FT_Size object.
*/
FT_Size_Internal :: *FT_Size_InternalRec_;

/**************************************************************************
*
* @struct:
*   FT_Size_Metrics
*
* @description:
*   The size metrics structure gives the metrics of a size object.
*
* @fields:
*   x_ppem ::
*     The width of the scaled EM square in pixels, hence the term 'ppem'
*     (pixels per EM).  It is also referred to as 'nominal width'.
*
*   y_ppem ::
*     The height of the scaled EM square in pixels, hence the term 'ppem'
*     (pixels per EM).  It is also referred to as 'nominal height'.
*
*   x_scale ::
*     A 16.16 fractional scaling value to convert horizontal metrics from
*     font units to 26.6 fractional pixels.  Only relevant for scalable
*     font formats.
*
*   y_scale ::
*     A 16.16 fractional scaling value to convert vertical metrics from
*     font units to 26.6 fractional pixels.  Only relevant for scalable
*     font formats.
*
*   ascender ::
*     The ascender in 26.6 fractional pixels, rounded up to an integer
*     value.  See @FT_FaceRec for the details.
*
*   descender ::
*     The descender in 26.6 fractional pixels, rounded down to an integer
*     value.  See @FT_FaceRec for the details.
*
*   height ::
*     The height in 26.6 fractional pixels, rounded to an integer value.
*     See @FT_FaceRec for the details.
*
*   max_advance ::
*     The maximum advance width in 26.6 fractional pixels, rounded to an
*     integer value.  See @FT_FaceRec for the details.
*
* @note:
*   The scaling values, if relevant, are determined first during a size
*   changing operation.  The remaining fields are then set by the driver.
*   For scalable formats, they are usually set to scaled values of the
*   corresponding fields in @FT_FaceRec.  Some values like ascender or
*   descender are rounded for historical reasons; more precise values (for
*   outline fonts) can be derived by scaling the corresponding @FT_FaceRec
*   values manually, with code similar to the following.
*
*   ```
*     scaled_ascender = FT_MulFix( face->ascender,
*                                  size_metrics->y_scale );
*   ```
*
*   Note that due to glyph hinting and the selected rendering mode these
*   values are usually not exact; consequently, they must be treated as
*   unreliable with an error margin of at least one pixel!
*
*   Indeed, the only way to get the exact metrics is to render _all_
*   glyphs.  As this would be a definite performance hit, it is up to
*   client applications to perform such computations.
*
*   The `FT_Size_Metrics` structure is valid for bitmap fonts also.
*
*
*   **TrueType fonts with native bytecode hinting**
*
*   All applications that handle TrueType fonts with native hinting must
*   be aware that TTFs expect different rounding of vertical font
*   dimensions.  The application has to cater for this, especially if it
*   wants to rely on a TTF's vertical data (for example, to properly align
*   box characters vertically).
*
*   Only the application knows _in advance_ that it is going to use native
*   hinting for TTFs!  FreeType, on the other hand, selects the hinting
*   mode not at the time of creating an @FT_Size object but much later,
*   namely while calling @FT_Load_Glyph.
*
*   Here is some pseudo code that illustrates a possible solution.
*
*   ```
*     font_format = FT_Get_Font_Format( face );
*
*     if ( !strcmp( font_format, "TrueType" ) &&
*          do_native_bytecode_hinting         )
*     {
*       ascender  = ROUND( FT_MulFix( face->ascender,
*                                     size_metrics->y_scale ) );
*       descender = ROUND( FT_MulFix( face->descender,
*                                     size_metrics->y_scale ) );
*     }
*     else
*     {
*       ascender  = size_metrics->ascender;
*       descender = size_metrics->descender;
*     }
*
*     height      = size_metrics->height;
*     max_advance = size_metrics->max_advance;
*   ```
*/
FT_Size_Metrics_ :: struct {
    x_ppem:      FT_UShort; /* horizontal pixels per EM               */
    y_ppem:      FT_UShort; /* vertical pixels per EM                 */

    x_scale:     FT_Fixed; /* scaling values used to convert font    */
    y_scale:     FT_Fixed; /* units to 26.6 fractional pixels        */

    ascender:    FT_Pos; /* ascender in 26.6 frac. pixels          */
    descender:   FT_Pos; /* descender in 26.6 frac. pixels         */
    height:      FT_Pos; /* text height in 26.6 frac. pixels       */
    max_advance: FT_Pos; /* max horizontal advance, in 26.6 pixels */
}

/**************************************************************************
*
* @struct:
*   FT_Size_Metrics
*
* @description:
*   The size metrics structure gives the metrics of a size object.
*
* @fields:
*   x_ppem ::
*     The width of the scaled EM square in pixels, hence the term 'ppem'
*     (pixels per EM).  It is also referred to as 'nominal width'.
*
*   y_ppem ::
*     The height of the scaled EM square in pixels, hence the term 'ppem'
*     (pixels per EM).  It is also referred to as 'nominal height'.
*
*   x_scale ::
*     A 16.16 fractional scaling value to convert horizontal metrics from
*     font units to 26.6 fractional pixels.  Only relevant for scalable
*     font formats.
*
*   y_scale ::
*     A 16.16 fractional scaling value to convert vertical metrics from
*     font units to 26.6 fractional pixels.  Only relevant for scalable
*     font formats.
*
*   ascender ::
*     The ascender in 26.6 fractional pixels, rounded up to an integer
*     value.  See @FT_FaceRec for the details.
*
*   descender ::
*     The descender in 26.6 fractional pixels, rounded down to an integer
*     value.  See @FT_FaceRec for the details.
*
*   height ::
*     The height in 26.6 fractional pixels, rounded to an integer value.
*     See @FT_FaceRec for the details.
*
*   max_advance ::
*     The maximum advance width in 26.6 fractional pixels, rounded to an
*     integer value.  See @FT_FaceRec for the details.
*
* @note:
*   The scaling values, if relevant, are determined first during a size
*   changing operation.  The remaining fields are then set by the driver.
*   For scalable formats, they are usually set to scaled values of the
*   corresponding fields in @FT_FaceRec.  Some values like ascender or
*   descender are rounded for historical reasons; more precise values (for
*   outline fonts) can be derived by scaling the corresponding @FT_FaceRec
*   values manually, with code similar to the following.
*
*   ```
*     scaled_ascender = FT_MulFix( face->ascender,
*                                  size_metrics->y_scale );
*   ```
*
*   Note that due to glyph hinting and the selected rendering mode these
*   values are usually not exact; consequently, they must be treated as
*   unreliable with an error margin of at least one pixel!
*
*   Indeed, the only way to get the exact metrics is to render _all_
*   glyphs.  As this would be a definite performance hit, it is up to
*   client applications to perform such computations.
*
*   The `FT_Size_Metrics` structure is valid for bitmap fonts also.
*
*
*   **TrueType fonts with native bytecode hinting**
*
*   All applications that handle TrueType fonts with native hinting must
*   be aware that TTFs expect different rounding of vertical font
*   dimensions.  The application has to cater for this, especially if it
*   wants to rely on a TTF's vertical data (for example, to properly align
*   box characters vertically).
*
*   Only the application knows _in advance_ that it is going to use native
*   hinting for TTFs!  FreeType, on the other hand, selects the hinting
*   mode not at the time of creating an @FT_Size object but much later,
*   namely while calling @FT_Load_Glyph.
*
*   Here is some pseudo code that illustrates a possible solution.
*
*   ```
*     font_format = FT_Get_Font_Format( face );
*
*     if ( !strcmp( font_format, "TrueType" ) &&
*          do_native_bytecode_hinting         )
*     {
*       ascender  = ROUND( FT_MulFix( face->ascender,
*                                     size_metrics->y_scale ) );
*       descender = ROUND( FT_MulFix( face->descender,
*                                     size_metrics->y_scale ) );
*     }
*     else
*     {
*       ascender  = size_metrics->ascender;
*       descender = size_metrics->descender;
*     }
*
*     height      = size_metrics->height;
*     max_advance = size_metrics->max_advance;
*   ```
*/
FT_Size_Metrics :: FT_Size_Metrics_;

/**************************************************************************
*
* @struct:
*   FT_SizeRec
*
* @description:
*   FreeType root size class structure.  A size object models a face
*   object at a given size.
*
* @fields:
*   face ::
*     Handle to the parent face object.
*
*   generic ::
*     A typeless pointer, unused by the FreeType library or any of its
*     drivers.  It can be used by client applications to link their own
*     data to each size object.
*
*   metrics ::
*     Metrics for this size object.  This field is read-only.
*/
FT_SizeRec_ :: struct {
    face:     FT_Face; /* parent face object              */
    generic:  FT_Generic; /* generic pointer for client uses */
    metrics:  FT_Size_Metrics; /* size metrics                    */
    internal: FT_Size_Internal;
}

/**************************************************************************
*
* @struct:
*   FT_SizeRec
*
* @description:
*   FreeType root size class structure.  A size object models a face
*   object at a given size.
*
* @fields:
*   face ::
*     Handle to the parent face object.
*
*   generic ::
*     A typeless pointer, unused by the FreeType library or any of its
*     drivers.  It can be used by client applications to link their own
*     data to each size object.
*
*   metrics ::
*     Metrics for this size object.  This field is read-only.
*/
FT_SizeRec :: FT_SizeRec_;

FT_SubGlyphRec_ :: struct {}
/**************************************************************************
*
* @struct:
*   FT_SubGlyph
*
* @description:
*   The subglyph structure is an internal object used to describe
*   subglyphs (for example, in the case of composites).
*
* @note:
*   The subglyph implementation is not part of the high-level API, hence
*   the forward structure declaration.
*
*   You can however retrieve subglyph information with
*   @FT_Get_SubGlyph_Info.
*/
FT_SubGlyph :: *FT_SubGlyphRec_;

FT_Slot_InternalRec_ :: struct {}
/**************************************************************************
*
* @type:
*   FT_Slot_Internal
*
* @description:
*   An opaque handle to an `FT_Slot_InternalRec` structure, used to model
*   private data of a given @FT_GlyphSlot object.
*/
FT_Slot_Internal :: *FT_Slot_InternalRec_;

/**************************************************************************
*
* @struct:
*   FT_GlyphSlotRec
*
* @description:
*   FreeType root glyph slot class structure.  A glyph slot is a container
*   where individual glyphs can be loaded, be they in outline or bitmap
*   format.
*
* @fields:
*   library ::
*     A handle to the FreeType library instance this slot belongs to.
*
*   face ::
*     A handle to the parent face object.
*
*   next ::
*     In some cases (like some font tools), several glyph slots per face
*     object can be a good thing.  As this is rare, the glyph slots are
*     listed through a direct, single-linked list using its `next` field.
*
*   glyph_index ::
*     [Since 2.10] The glyph index passed as an argument to @FT_Load_Glyph
*     while initializing the glyph slot.
*
*   generic ::
*     A typeless pointer unused by the FreeType library or any of its
*     drivers.  It can be used by client applications to link their own
*     data to each glyph slot object.
*
*   metrics ::
*     The metrics of the last loaded glyph in the slot.  The returned
*     values depend on the last load flags (see the @FT_Load_Glyph API
*     function) and can be expressed either in 26.6 fractional pixels or
*     font units.
*
*     Note that even when the glyph image is transformed, the metrics are
*     not.
*
*   linearHoriAdvance ::
*     The advance width of the unhinted glyph.  Its value is expressed in
*     16.16 fractional pixels, unless @FT_LOAD_LINEAR_DESIGN is set when
*     loading the glyph.  This field can be important to perform correct
*     WYSIWYG layout.  Only relevant for scalable glyphs.
*
*   linearVertAdvance ::
*     The advance height of the unhinted glyph.  Its value is expressed in
*     16.16 fractional pixels, unless @FT_LOAD_LINEAR_DESIGN is set when
*     loading the glyph.  This field can be important to perform correct
*     WYSIWYG layout.  Only relevant for scalable glyphs.
*
*   advance ::
*     This shorthand is, depending on @FT_LOAD_IGNORE_TRANSFORM, the
*     transformed (hinted) advance width for the glyph, in 26.6 fractional
*     pixel format.  As specified with @FT_LOAD_VERTICAL_LAYOUT, it uses
*     either the `horiAdvance` or the `vertAdvance` value of `metrics`
*     field.
*
*   format ::
*     This field indicates the format of the image contained in the glyph
*     slot.  Typically @FT_GLYPH_FORMAT_BITMAP, @FT_GLYPH_FORMAT_OUTLINE,
*     or @FT_GLYPH_FORMAT_COMPOSITE, but other values are possible.
*
*   bitmap ::
*     This field is used as a bitmap descriptor.  Note that the address
*     and content of the bitmap buffer can change between calls of
*     @FT_Load_Glyph and a few other functions.
*
*   bitmap_left ::
*     The bitmap's left bearing expressed in integer pixels.
*
*   bitmap_top ::
*     The bitmap's top bearing expressed in integer pixels.  This is the
*     distance from the baseline to the top-most glyph scanline, upwards
*     y~coordinates being **positive**.
*
*   outline ::
*     The outline descriptor for the current glyph image if its format is
*     @FT_GLYPH_FORMAT_OUTLINE.  Once a glyph is loaded, `outline` can be
*     transformed, distorted, emboldened, etc.  However, it must not be
*     freed.
*
*     [Since 2.10.1] If @FT_LOAD_NO_SCALE is set, outline coordinates of
*     OpenType Font Variations for a selected instance are internally
*     handled as 26.6 fractional font units but returned as (rounded)
*     integers, as expected.  To get unrounded font units, don't use
*     @FT_LOAD_NO_SCALE but load the glyph with @FT_LOAD_NO_HINTING and
*     scale it, using the font's `units_per_EM` value as the ppem.
*
*   num_subglyphs ::
*     The number of subglyphs in a composite glyph.  This field is only
*     valid for the composite glyph format that should normally only be
*     loaded with the @FT_LOAD_NO_RECURSE flag.
*
*   subglyphs ::
*     An array of subglyph descriptors for composite glyphs.  There are
*     `num_subglyphs` elements in there.  Currently internal to FreeType.
*
*   control_data ::
*     Certain font drivers can also return the control data for a given
*     glyph image (e.g.  TrueType bytecode, Type~1 charstrings, etc.).
*     This field is a pointer to such data; it is currently internal to
*     FreeType.
*
*   control_len ::
*     This is the length in bytes of the control data.  Currently internal
*     to FreeType.
*
*   other ::
*     Reserved.
*
*   lsb_delta ::
*     The difference between hinted and unhinted left side bearing while
*     auto-hinting is active.  Zero otherwise.
*
*   rsb_delta ::
*     The difference between hinted and unhinted right side bearing while
*     auto-hinting is active.  Zero otherwise.
*
* @note:
*   If @FT_Load_Glyph is called with default flags (see @FT_LOAD_DEFAULT)
*   the glyph image is loaded in the glyph slot in its native format
*   (e.g., an outline glyph for TrueType and Type~1 formats).  [Since 2.9]
*   The prospective bitmap metrics are calculated according to
*   @FT_LOAD_TARGET_XXX and other flags even for the outline glyph, even
*   if @FT_LOAD_RENDER is not set.
*
*   This image can later be converted into a bitmap by calling
*   @FT_Render_Glyph.  This function searches the current renderer for the
*   native image's format, then invokes it.
*
*   The renderer is in charge of transforming the native image through the
*   slot's face transformation fields, then converting it into a bitmap
*   that is returned in `slot->bitmap`.
*
*   Note that `slot->bitmap_left` and `slot->bitmap_top` are also used to
*   specify the position of the bitmap relative to the current pen
*   position (e.g., coordinates (0,0) on the baseline).  Of course,
*   `slot->format` is also changed to @FT_GLYPH_FORMAT_BITMAP.
*
*   Here is a small pseudo code fragment that shows how to use `lsb_delta`
*   and `rsb_delta` to do fractional positioning of glyphs:
*
*   ```
*     FT_GlyphSlot  slot     = face->glyph;
*     FT_Pos        origin_x = 0;
*
*
*     for all glyphs do
*       <load glyph with `FT_Load_Glyph'>
*
*       FT_Outline_Translate( slot->outline, origin_x & 63, 0 );
*
*       <save glyph image, or render glyph, or ...>
*
*       <compute kern between current and next glyph
*        and add it to `origin_x'>
*
*       origin_x += slot->advance.x;
*       origin_x += slot->lsb_delta - slot->rsb_delta;
*     endfor
*   ```
*
*   Here is another small pseudo code fragment that shows how to use
*   `lsb_delta` and `rsb_delta` to improve integer positioning of glyphs:
*
*   ```
*     FT_GlyphSlot  slot           = face->glyph;
*     FT_Pos        origin_x       = 0;
*     FT_Pos        prev_rsb_delta = 0;
*
*
*     for all glyphs do
*       <compute kern between current and previous glyph
*        and add it to `origin_x'>
*
*       <load glyph with `FT_Load_Glyph'>
*
*       if ( prev_rsb_delta - slot->lsb_delta >  32 )
*         origin_x -= 64;
*       else if ( prev_rsb_delta - slot->lsb_delta < -31 )
*         origin_x += 64;
*
*       prev_rsb_delta = slot->rsb_delta;
*
*       <save glyph image, or render glyph, or ...>
*
*       origin_x += slot->advance.x;
*     endfor
*   ```
*
*   If you use strong auto-hinting, you **must** apply these delta values!
*   Otherwise you will experience far too large inter-glyph spacing at
*   small rendering sizes in most cases.  Note that it doesn't harm to use
*   the above code for other hinting modes also, since the delta values
*   are zero then.
*/
FT_GlyphSlotRec_ :: struct {
    library:           FT_Library;
    face:              FT_Face;
    next:              FT_GlyphSlot;
    glyph_index:       FT_UInt; /* new in 2.10; was reserved previously */
    generic:           FT_Generic;

    metrics:           FT_Glyph_Metrics;
    linearHoriAdvance: FT_Fixed;
    linearVertAdvance: FT_Fixed;
    advance:           FT_Vector;

    format:            FT_Glyph_Format;

    bitmap:            FT_Bitmap;
    bitmap_left:       FT_Int;
    bitmap_top:        FT_Int;

    outline:           FT_Outline;

    num_subglyphs:     FT_UInt;
    subglyphs:         FT_SubGlyph;

    control_data:      *void;
    control_len:       s64;

    lsb_delta:         FT_Pos;
    rsb_delta:         FT_Pos;

    other:             *void;

    internal:          FT_Slot_Internal;
}

/**************************************************************************
*
* @struct:
*   FT_GlyphSlotRec
*
* @description:
*   FreeType root glyph slot class structure.  A glyph slot is a container
*   where individual glyphs can be loaded, be they in outline or bitmap
*   format.
*
* @fields:
*   library ::
*     A handle to the FreeType library instance this slot belongs to.
*
*   face ::
*     A handle to the parent face object.
*
*   next ::
*     In some cases (like some font tools), several glyph slots per face
*     object can be a good thing.  As this is rare, the glyph slots are
*     listed through a direct, single-linked list using its `next` field.
*
*   glyph_index ::
*     [Since 2.10] The glyph index passed as an argument to @FT_Load_Glyph
*     while initializing the glyph slot.
*
*   generic ::
*     A typeless pointer unused by the FreeType library or any of its
*     drivers.  It can be used by client applications to link their own
*     data to each glyph slot object.
*
*   metrics ::
*     The metrics of the last loaded glyph in the slot.  The returned
*     values depend on the last load flags (see the @FT_Load_Glyph API
*     function) and can be expressed either in 26.6 fractional pixels or
*     font units.
*
*     Note that even when the glyph image is transformed, the metrics are
*     not.
*
*   linearHoriAdvance ::
*     The advance width of the unhinted glyph.  Its value is expressed in
*     16.16 fractional pixels, unless @FT_LOAD_LINEAR_DESIGN is set when
*     loading the glyph.  This field can be important to perform correct
*     WYSIWYG layout.  Only relevant for scalable glyphs.
*
*   linearVertAdvance ::
*     The advance height of the unhinted glyph.  Its value is expressed in
*     16.16 fractional pixels, unless @FT_LOAD_LINEAR_DESIGN is set when
*     loading the glyph.  This field can be important to perform correct
*     WYSIWYG layout.  Only relevant for scalable glyphs.
*
*   advance ::
*     This shorthand is, depending on @FT_LOAD_IGNORE_TRANSFORM, the
*     transformed (hinted) advance width for the glyph, in 26.6 fractional
*     pixel format.  As specified with @FT_LOAD_VERTICAL_LAYOUT, it uses
*     either the `horiAdvance` or the `vertAdvance` value of `metrics`
*     field.
*
*   format ::
*     This field indicates the format of the image contained in the glyph
*     slot.  Typically @FT_GLYPH_FORMAT_BITMAP, @FT_GLYPH_FORMAT_OUTLINE,
*     or @FT_GLYPH_FORMAT_COMPOSITE, but other values are possible.
*
*   bitmap ::
*     This field is used as a bitmap descriptor.  Note that the address
*     and content of the bitmap buffer can change between calls of
*     @FT_Load_Glyph and a few other functions.
*
*   bitmap_left ::
*     The bitmap's left bearing expressed in integer pixels.
*
*   bitmap_top ::
*     The bitmap's top bearing expressed in integer pixels.  This is the
*     distance from the baseline to the top-most glyph scanline, upwards
*     y~coordinates being **positive**.
*
*   outline ::
*     The outline descriptor for the current glyph image if its format is
*     @FT_GLYPH_FORMAT_OUTLINE.  Once a glyph is loaded, `outline` can be
*     transformed, distorted, emboldened, etc.  However, it must not be
*     freed.
*
*     [Since 2.10.1] If @FT_LOAD_NO_SCALE is set, outline coordinates of
*     OpenType Font Variations for a selected instance are internally
*     handled as 26.6 fractional font units but returned as (rounded)
*     integers, as expected.  To get unrounded font units, don't use
*     @FT_LOAD_NO_SCALE but load the glyph with @FT_LOAD_NO_HINTING and
*     scale it, using the font's `units_per_EM` value as the ppem.
*
*   num_subglyphs ::
*     The number of subglyphs in a composite glyph.  This field is only
*     valid for the composite glyph format that should normally only be
*     loaded with the @FT_LOAD_NO_RECURSE flag.
*
*   subglyphs ::
*     An array of subglyph descriptors for composite glyphs.  There are
*     `num_subglyphs` elements in there.  Currently internal to FreeType.
*
*   control_data ::
*     Certain font drivers can also return the control data for a given
*     glyph image (e.g.  TrueType bytecode, Type~1 charstrings, etc.).
*     This field is a pointer to such data; it is currently internal to
*     FreeType.
*
*   control_len ::
*     This is the length in bytes of the control data.  Currently internal
*     to FreeType.
*
*   other ::
*     Reserved.
*
*   lsb_delta ::
*     The difference between hinted and unhinted left side bearing while
*     auto-hinting is active.  Zero otherwise.
*
*   rsb_delta ::
*     The difference between hinted and unhinted right side bearing while
*     auto-hinting is active.  Zero otherwise.
*
* @note:
*   If @FT_Load_Glyph is called with default flags (see @FT_LOAD_DEFAULT)
*   the glyph image is loaded in the glyph slot in its native format
*   (e.g., an outline glyph for TrueType and Type~1 formats).  [Since 2.9]
*   The prospective bitmap metrics are calculated according to
*   @FT_LOAD_TARGET_XXX and other flags even for the outline glyph, even
*   if @FT_LOAD_RENDER is not set.
*
*   This image can later be converted into a bitmap by calling
*   @FT_Render_Glyph.  This function searches the current renderer for the
*   native image's format, then invokes it.
*
*   The renderer is in charge of transforming the native image through the
*   slot's face transformation fields, then converting it into a bitmap
*   that is returned in `slot->bitmap`.
*
*   Note that `slot->bitmap_left` and `slot->bitmap_top` are also used to
*   specify the position of the bitmap relative to the current pen
*   position (e.g., coordinates (0,0) on the baseline).  Of course,
*   `slot->format` is also changed to @FT_GLYPH_FORMAT_BITMAP.
*
*   Here is a small pseudo code fragment that shows how to use `lsb_delta`
*   and `rsb_delta` to do fractional positioning of glyphs:
*
*   ```
*     FT_GlyphSlot  slot     = face->glyph;
*     FT_Pos        origin_x = 0;
*
*
*     for all glyphs do
*       <load glyph with `FT_Load_Glyph'>
*
*       FT_Outline_Translate( slot->outline, origin_x & 63, 0 );
*
*       <save glyph image, or render glyph, or ...>
*
*       <compute kern between current and next glyph
*        and add it to `origin_x'>
*
*       origin_x += slot->advance.x;
*       origin_x += slot->lsb_delta - slot->rsb_delta;
*     endfor
*   ```
*
*   Here is another small pseudo code fragment that shows how to use
*   `lsb_delta` and `rsb_delta` to improve integer positioning of glyphs:
*
*   ```
*     FT_GlyphSlot  slot           = face->glyph;
*     FT_Pos        origin_x       = 0;
*     FT_Pos        prev_rsb_delta = 0;
*
*
*     for all glyphs do
*       <compute kern between current and previous glyph
*        and add it to `origin_x'>
*
*       <load glyph with `FT_Load_Glyph'>
*
*       if ( prev_rsb_delta - slot->lsb_delta >  32 )
*         origin_x -= 64;
*       else if ( prev_rsb_delta - slot->lsb_delta < -31 )
*         origin_x += 64;
*
*       prev_rsb_delta = slot->rsb_delta;
*
*       <save glyph image, or render glyph, or ...>
*
*       origin_x += slot->advance.x;
*     endfor
*   ```
*
*   If you use strong auto-hinting, you **must** apply these delta values!
*   Otherwise you will experience far too large inter-glyph spacing at
*   small rendering sizes in most cases.  Note that it doesn't harm to use
*   the above code for other hinting modes also, since the delta values
*   are zero then.
*/
FT_GlyphSlotRec :: FT_GlyphSlotRec_;

/**************************************************************************
*
* @function:
*   FT_Init_FreeType
*
* @description:
*   Initialize a new FreeType library object.  The set of modules that are
*   registered by this function is determined at build time.
*
* @output:
*   alibrary ::
*     A handle to a new library object.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   In case you want to provide your own memory allocating routines, use
*   @FT_New_Library instead, followed by a call to @FT_Add_Default_Modules
*   (or a series of calls to @FT_Add_Module) and
*   @FT_Set_Default_Properties.
*
*   See the documentation of @FT_Library and @FT_Face for multi-threading
*   issues.
*
*   If you need reference-counting (cf. @FT_Reference_Library), use
*   @FT_New_Library and @FT_Done_Library.
*
*   If compilation option `FT_CONFIG_OPTION_ENVIRONMENT_PROPERTIES` is
*   set, this function reads the `FREETYPE_PROPERTIES` environment
*   variable to control driver properties.  See section @properties for
*   more.
*/
FT_Init_FreeType :: (alibrary: *FT_Library) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Done_FreeType
*
* @description:
*   Destroy a given FreeType library object and all of its children,
*   including resources, drivers, faces, sizes, etc.
*
* @input:
*   library ::
*     A handle to the target library object.
*
* @return:
*   FreeType error code.  0~means success.
*/
FT_Done_FreeType :: (library: FT_Library) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @struct:
*   FT_Parameter
*
* @description:
*   A simple structure to pass more or less generic parameters to
*   @FT_Open_Face and @FT_Face_Properties.
*
* @fields:
*   tag ::
*     A four-byte identification tag.
*
*   data ::
*     A pointer to the parameter data.
*
* @note:
*   The ID and function of parameters are driver-specific.  See section
*   @parameter_tags for more information.
*/
FT_Parameter_ :: struct {
    tag:  FT_ULong;
    data: FT_Pointer;
}

/**************************************************************************
*
* @struct:
*   FT_Parameter
*
* @description:
*   A simple structure to pass more or less generic parameters to
*   @FT_Open_Face and @FT_Face_Properties.
*
* @fields:
*   tag ::
*     A four-byte identification tag.
*
*   data ::
*     A pointer to the parameter data.
*
* @note:
*   The ID and function of parameters are driver-specific.  See section
*   @parameter_tags for more information.
*/
FT_Parameter :: FT_Parameter_;

/**************************************************************************
*
* @struct:
*   FT_Open_Args
*
* @description:
*   A structure to indicate how to open a new font file or stream.  A
*   pointer to such a structure can be used as a parameter for the
*   functions @FT_Open_Face and @FT_Attach_Stream.
*
* @fields:
*   flags ::
*     A set of bit flags indicating how to use the structure.
*
*   memory_base ::
*     The first byte of the file in memory.
*
*   memory_size ::
*     The size in bytes of the file in memory.
*
*   pathname ::
*     A pointer to an 8-bit file pathname, which must be a C~string (i.e.,
*     no null bytes except at the very end).  The pointer is not owned by
*     FreeType.
*
*   stream ::
*     A handle to a source stream object.
*
*   driver ::
*     This field is exclusively used by @FT_Open_Face; it simply specifies
*     the font driver to use for opening the face.  If set to `NULL`,
*     FreeType tries to load the face with each one of the drivers in its
*     list.
*
*   num_params ::
*     The number of extra parameters.
*
*   params ::
*     Extra parameters passed to the font driver when opening a new face.
*
* @note:
*   The stream type is determined by the contents of `flags`:
*
*   If the @FT_OPEN_MEMORY bit is set, assume that this is a memory file
*   of `memory_size` bytes, located at `memory_address`.  The data are not
*   copied, and the client is responsible for releasing and destroying
*   them _after_ the corresponding call to @FT_Done_Face.
*
*   Otherwise, if the @FT_OPEN_STREAM bit is set, assume that a custom
*   input stream `stream` is used.
*
*   Otherwise, if the @FT_OPEN_PATHNAME bit is set, assume that this is a
*   normal file and use `pathname` to open it.
*
*   If none of the above bits are set or if multiple are set at the same
*   time, the flags are invalid and @FT_Open_Face fails.
*
*   If the @FT_OPEN_DRIVER bit is set, @FT_Open_Face only tries to open
*   the file with the driver whose handler is in `driver`.
*
*   If the @FT_OPEN_PARAMS bit is set, the parameters given by
*   `num_params` and `params` is used.  They are ignored otherwise.
*
*   Ideally, both the `pathname` and `params` fields should be tagged as
*   'const'; this is missing for API backward compatibility.  In other
*   words, applications should treat them as read-only.
*/
FT_Open_Args_ :: struct {
    flags:       FT_UInt;
    memory_base: *FT_Byte;
    memory_size: FT_Long;
    pathname:    *FT_String;
    stream:      FT_Stream;
    driver:      FT_Module;
    num_params:  FT_Int;
    params:      *FT_Parameter;
}

/**************************************************************************
*
* @struct:
*   FT_Open_Args
*
* @description:
*   A structure to indicate how to open a new font file or stream.  A
*   pointer to such a structure can be used as a parameter for the
*   functions @FT_Open_Face and @FT_Attach_Stream.
*
* @fields:
*   flags ::
*     A set of bit flags indicating how to use the structure.
*
*   memory_base ::
*     The first byte of the file in memory.
*
*   memory_size ::
*     The size in bytes of the file in memory.
*
*   pathname ::
*     A pointer to an 8-bit file pathname, which must be a C~string (i.e.,
*     no null bytes except at the very end).  The pointer is not owned by
*     FreeType.
*
*   stream ::
*     A handle to a source stream object.
*
*   driver ::
*     This field is exclusively used by @FT_Open_Face; it simply specifies
*     the font driver to use for opening the face.  If set to `NULL`,
*     FreeType tries to load the face with each one of the drivers in its
*     list.
*
*   num_params ::
*     The number of extra parameters.
*
*   params ::
*     Extra parameters passed to the font driver when opening a new face.
*
* @note:
*   The stream type is determined by the contents of `flags`:
*
*   If the @FT_OPEN_MEMORY bit is set, assume that this is a memory file
*   of `memory_size` bytes, located at `memory_address`.  The data are not
*   copied, and the client is responsible for releasing and destroying
*   them _after_ the corresponding call to @FT_Done_Face.
*
*   Otherwise, if the @FT_OPEN_STREAM bit is set, assume that a custom
*   input stream `stream` is used.
*
*   Otherwise, if the @FT_OPEN_PATHNAME bit is set, assume that this is a
*   normal file and use `pathname` to open it.
*
*   If none of the above bits are set or if multiple are set at the same
*   time, the flags are invalid and @FT_Open_Face fails.
*
*   If the @FT_OPEN_DRIVER bit is set, @FT_Open_Face only tries to open
*   the file with the driver whose handler is in `driver`.
*
*   If the @FT_OPEN_PARAMS bit is set, the parameters given by
*   `num_params` and `params` is used.  They are ignored otherwise.
*
*   Ideally, both the `pathname` and `params` fields should be tagged as
*   'const'; this is missing for API backward compatibility.  In other
*   words, applications should treat them as read-only.
*/
FT_Open_Args :: FT_Open_Args_;

/**************************************************************************
*
* @function:
*   FT_New_Face
*
* @description:
*   Call @FT_Open_Face to open a font by its pathname.
*
* @inout:
*   library ::
*     A handle to the library resource.
*
* @input:
*   pathname ::
*     A path to the font file.
*
*   face_index ::
*     See @FT_Open_Face for a detailed description of this parameter.
*
* @output:
*   aface ::
*     A handle to a new face object.  If `face_index` is greater than or
*     equal to zero, it must be non-`NULL`.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   The `pathname` string should be recognizable as such by a standard
*   `fopen` call on your system; in particular, this means that `pathname`
*   must not contain null bytes.  If that is not sufficient to address all
*   file name possibilities (for example, to handle wide character file
*   names on Windows in UTF-16 encoding) you might use @FT_Open_Face to
*   pass a memory array or a stream object instead.
*
*   Use @FT_Done_Face to destroy the created @FT_Face object (along with
*   its slot and sizes).
*/
FT_New_Face :: (library: FT_Library, filepathname: *u8, face_index: FT_Long, aface: *FT_Face) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_New_Memory_Face
*
* @description:
*   Call @FT_Open_Face to open a font that has been loaded into memory.
*
* @inout:
*   library ::
*     A handle to the library resource.
*
* @input:
*   file_base ::
*     A pointer to the beginning of the font data.
*
*   file_size ::
*     The size of the memory chunk used by the font data.
*
*   face_index ::
*     See @FT_Open_Face for a detailed description of this parameter.
*
* @output:
*   aface ::
*     A handle to a new face object.  If `face_index` is greater than or
*     equal to zero, it must be non-`NULL`.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   You must not deallocate the memory before calling @FT_Done_Face.
*/
FT_New_Memory_Face :: (library: FT_Library, file_base: *FT_Byte, file_size: FT_Long, face_index: FT_Long, aface: *FT_Face) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Open_Face
*
* @description:
*   Create a face object from a given resource described by @FT_Open_Args.
*
* @inout:
*   library ::
*     A handle to the library resource.
*
* @input:
*   args ::
*     A pointer to an `FT_Open_Args` structure that must be filled by the
*     caller.
*
*   face_index ::
*     This field holds two different values.  Bits 0-15 are the index of
*     the face in the font file (starting with value~0).  Set it to~0 if
*     there is only one face in the font file.
*
*     [Since 2.6.1] Bits 16-30 are relevant to TrueType GX and OpenType
*     Font Variations only, specifying the named instance index for the
*     current face index (starting with value~1; value~0 makes FreeType
*     ignore named instances).  For non-variation fonts, bits 16-30 are
*     ignored.  Assuming that you want to access the third named instance
*     in face~4, `face_index` should be set to 0x00030004.  If you want
*     to access face~4 without variation handling, simply set
*     `face_index` to value~4.
*
*     `FT_Open_Face` and its siblings can be used to quickly check whether
*     the font format of a given font resource is supported by FreeType.
*     In general, if the `face_index` argument is negative, the function's
*     return value is~0 if the font format is recognized, or non-zero
*     otherwise.  The function allocates a more or less empty face handle
*     in `*aface` (if `aface` isn't `NULL`); the only two useful fields in
*     this special case are `face->num_faces` and `face->style_flags`.
*     For any negative value of `face_index`, `face->num_faces` gives the
*     number of faces within the font file.  For the negative value
*     '-(N+1)' (with 'N' a non-negative 16-bit value), bits 16-30 in
*     `face->style_flags` give the number of named instances in face 'N'
*     if we have a variation font (or zero otherwise).  After examination,
*     the returned @FT_Face structure should be deallocated with a call to
*     @FT_Done_Face.
*
* @output:
*   aface ::
*     A handle to a new face object.  If `face_index` is greater than or
*     equal to zero, it must be non-`NULL`.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   Unlike FreeType 1.x, this function automatically creates a glyph slot
*   for the face object that can be accessed directly through
*   `face->glyph`.
*
*   Each new face object created with this function also owns a default
*   @FT_Size object, accessible as `face->size`.
*
*   One @FT_Library instance can have multiple face objects, that is,
*   @FT_Open_Face and its siblings can be called multiple times using the
*   same `library` argument.
*
*   See the discussion of reference counters in the description of
*   @FT_Reference_Face.
*
*   If `FT_OPEN_STREAM` is set in `args->flags`, the stream in
*   `args->stream` is automatically closed before this function returns
*   any error (including `FT_Err_Invalid_Argument`).
*
* @example:
*   To loop over all faces, use code similar to the following snippet
*   (omitting the error handling).
*
*   ```
*     ...
*     FT_Face  face;
*     FT_Long  i, num_faces;
*
*
*     error = FT_Open_Face( library, args, -1, &face );
*     if ( error ) { ... }
*
*     num_faces = face->num_faces;
*     FT_Done_Face( face );
*
*     for ( i = 0; i < num_faces; i++ )
*     {
*       ...
*       error = FT_Open_Face( library, args, i, &face );
*       ...
*       FT_Done_Face( face );
*       ...
*     }
*   ```
*
*   To loop over all valid values for `face_index`, use something similar
*   to the following snippet, again without error handling.  The code
*   accesses all faces immediately (thus only a single call of
*   `FT_Open_Face` within the do-loop), with and without named instances.
*
*   ```
*     ...
*     FT_Face  face;
*
*     FT_Long  num_faces     = 0;
*     FT_Long  num_instances = 0;
*
*     FT_Long  face_idx     = 0;
*     FT_Long  instance_idx = 0;
*
*
*     do
*     {
*       FT_Long  id = ( instance_idx << 16 ) + face_idx;
*
*
*       error = FT_Open_Face( library, args, id, &face );
*       if ( error ) { ... }
*
*       num_faces     = face->num_faces;
*       num_instances = face->style_flags >> 16;
*
*       ...
*
*       FT_Done_Face( face );
*
*       if ( instance_idx < num_instances )
*         instance_idx++;
*       else
*       {
*         face_idx++;
*         instance_idx = 0;
*       }
*
*     } while ( face_idx < num_faces )
*   ```
*/
FT_Open_Face :: (library: FT_Library, args: *FT_Open_Args, face_index: FT_Long, aface: *FT_Face) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Attach_File
*
* @description:
*   Call @FT_Attach_Stream to attach a file.
*
* @inout:
*   face ::
*     The target face object.
*
* @input:
*   filepathname ::
*     The pathname.
*
* @return:
*   FreeType error code.  0~means success.
*/
FT_Attach_File :: (face: FT_Face, filepathname: *u8) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Attach_Stream
*
* @description:
*   'Attach' data to a face object.  Normally, this is used to read
*   additional information for the face object.  For example, you can
*   attach an AFM file that comes with a Type~1 font to get the kerning
*   values and other metrics.
*
* @inout:
*   face ::
*     The target face object.
*
* @input:
*   parameters ::
*     A pointer to @FT_Open_Args that must be filled by the caller.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   The meaning of the 'attach' (i.e., what really happens when the new
*   file is read) is not fixed by FreeType itself.  It really depends on
*   the font format (and thus the font driver).
*
*   Client applications are expected to know what they are doing when
*   invoking this function.  Most drivers simply do not implement file or
*   stream attachments.
*/
FT_Attach_Stream :: (face: FT_Face, parameters: *FT_Open_Args) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Reference_Face
*
* @description:
*   A counter gets initialized to~1 at the time an @FT_Face structure is
*   created.  This function increments the counter.  @FT_Done_Face then
*   only destroys a face if the counter is~1, otherwise it simply
*   decrements the counter.
*
*   This function helps in managing life-cycles of structures that
*   reference @FT_Face objects.
*
* @input:
*   face ::
*     A handle to a target face object.
*
* @return:
*   FreeType error code.  0~means success.
*
* @since:
*   2.4.2
*
*/
FT_Reference_Face :: (face: FT_Face) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Done_Face
*
* @description:
*   Discard a given face object, as well as all of its child slots and
*   sizes.
*
* @input:
*   face ::
*     A handle to a target face object.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   See the discussion of reference counters in the description of
*   @FT_Reference_Face.
*/
FT_Done_Face :: (face: FT_Face) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Select_Size
*
* @description:
*   Select a bitmap strike.  To be more precise, this function sets the
*   scaling factors of the active @FT_Size object in a face so that
*   bitmaps from this particular strike are taken by @FT_Load_Glyph and
*   friends.
*
* @inout:
*   face ::
*     A handle to a target face object.
*
* @input:
*   strike_index ::
*     The index of the bitmap strike in the `available_sizes` field of
*     @FT_FaceRec structure.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   For bitmaps embedded in outline fonts it is common that only a subset
*   of the available glyphs at a given ppem value is available.  FreeType
*   silently uses outlines if there is no bitmap for a given glyph index.
*
*   For TrueType GX and OpenType Font Variations, a bitmap strike makes
*   sense only if the default instance is active (that is, no glyph
*   variation takes place); otherwise, FreeType simply ignores bitmap
*   strikes.  The same is true for all named instances that are different
*   from the default instance.
*
*   Don't use this function if you are using the FreeType cache API.
*/
FT_Select_Size :: (face: FT_Face, strike_index: FT_Int) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @enum:
*   FT_Size_Request_Type
*
* @description:
*   An enumeration type that lists the supported size request types, i.e.,
*   what input size (in font units) maps to the requested output size (in
*   pixels, as computed from the arguments of @FT_Size_Request).
*
* @values:
*   FT_SIZE_REQUEST_TYPE_NOMINAL ::
*     The nominal size.  The `units_per_EM` field of @FT_FaceRec is used
*     to determine both scaling values.
*
*     This is the standard scaling found in most applications.  In
*     particular, use this size request type for TrueType fonts if they
*     provide optical scaling or something similar.  Note, however, that
*     `units_per_EM` is a rather abstract value which bears no relation to
*     the actual size of the glyphs in a font.
*
*   FT_SIZE_REQUEST_TYPE_REAL_DIM ::
*     The real dimension.  The sum of the `ascender` and (minus of) the
*     `descender` fields of @FT_FaceRec is used to determine both scaling
*     values.
*
*   FT_SIZE_REQUEST_TYPE_BBOX ::
*     The font bounding box.  The width and height of the `bbox` field of
*     @FT_FaceRec are used to determine the horizontal and vertical
*     scaling value, respectively.
*
*   FT_SIZE_REQUEST_TYPE_CELL ::
*     The `max_advance_width` field of @FT_FaceRec is used to determine
*     the horizontal scaling value; the vertical scaling value is
*     determined the same way as @FT_SIZE_REQUEST_TYPE_REAL_DIM does.
*     Finally, both scaling values are set to the smaller one.  This type
*     is useful if you want to specify the font size for, say, a window of
*     a given dimension and 80x24 cells.
*
*   FT_SIZE_REQUEST_TYPE_SCALES ::
*     Specify the scaling values directly.
*
* @note:
*   The above descriptions only apply to scalable formats.  For bitmap
*   formats, the behaviour is up to the driver.
*
*   See the note section of @FT_Size_Metrics if you wonder how size
*   requesting relates to scaling values.
*/
FT_Size_Request_Type_ :: enum u32 {
    NOMINAL  :: 0;
    REAL_DIM :: 1;
    BBOX     :: 2;
    CELL     :: 3;
    SCALES   :: 4;

    MAX      :: 5;

    FT_SIZE_REQUEST_TYPE_NOMINAL  :: NOMINAL;
    FT_SIZE_REQUEST_TYPE_REAL_DIM :: REAL_DIM;
    FT_SIZE_REQUEST_TYPE_BBOX     :: BBOX;
    FT_SIZE_REQUEST_TYPE_CELL     :: CELL;
    FT_SIZE_REQUEST_TYPE_SCALES   :: SCALES;

    FT_SIZE_REQUEST_TYPE_MAX      :: MAX;
}

/**************************************************************************
*
* @enum:
*   FT_Size_Request_Type
*
* @description:
*   An enumeration type that lists the supported size request types, i.e.,
*   what input size (in font units) maps to the requested output size (in
*   pixels, as computed from the arguments of @FT_Size_Request).
*
* @values:
*   FT_SIZE_REQUEST_TYPE_NOMINAL ::
*     The nominal size.  The `units_per_EM` field of @FT_FaceRec is used
*     to determine both scaling values.
*
*     This is the standard scaling found in most applications.  In
*     particular, use this size request type for TrueType fonts if they
*     provide optical scaling or something similar.  Note, however, that
*     `units_per_EM` is a rather abstract value which bears no relation to
*     the actual size of the glyphs in a font.
*
*   FT_SIZE_REQUEST_TYPE_REAL_DIM ::
*     The real dimension.  The sum of the `ascender` and (minus of) the
*     `descender` fields of @FT_FaceRec is used to determine both scaling
*     values.
*
*   FT_SIZE_REQUEST_TYPE_BBOX ::
*     The font bounding box.  The width and height of the `bbox` field of
*     @FT_FaceRec are used to determine the horizontal and vertical
*     scaling value, respectively.
*
*   FT_SIZE_REQUEST_TYPE_CELL ::
*     The `max_advance_width` field of @FT_FaceRec is used to determine
*     the horizontal scaling value; the vertical scaling value is
*     determined the same way as @FT_SIZE_REQUEST_TYPE_REAL_DIM does.
*     Finally, both scaling values are set to the smaller one.  This type
*     is useful if you want to specify the font size for, say, a window of
*     a given dimension and 80x24 cells.
*
*   FT_SIZE_REQUEST_TYPE_SCALES ::
*     Specify the scaling values directly.
*
* @note:
*   The above descriptions only apply to scalable formats.  For bitmap
*   formats, the behaviour is up to the driver.
*
*   See the note section of @FT_Size_Metrics if you wonder how size
*   requesting relates to scaling values.
*/
FT_Size_Request_Type :: FT_Size_Request_Type_;

/**************************************************************************
*
* @struct:
*   FT_Size_RequestRec
*
* @description:
*   A structure to model a size request.
*
* @fields:
*   type ::
*     See @FT_Size_Request_Type.
*
*   width ::
*     The desired width, given as a 26.6 fractional point value (with 72pt
*     = 1in).
*
*   height ::
*     The desired height, given as a 26.6 fractional point value (with
*     72pt = 1in).
*
*   horiResolution ::
*     The horizontal resolution (dpi, i.e., pixels per inch).  If set to
*     zero, `width` is treated as a 26.6 fractional **pixel** value, which
*     gets internally rounded to an integer.
*
*   vertResolution ::
*     The vertical resolution (dpi, i.e., pixels per inch).  If set to
*     zero, `height` is treated as a 26.6 fractional **pixel** value,
*     which gets internally rounded to an integer.
*
* @note:
*   If `width` is zero, the horizontal scaling value is set equal to the
*   vertical scaling value, and vice versa.
*
*   If `type` is `FT_SIZE_REQUEST_TYPE_SCALES`, `width` and `height` are
*   interpreted directly as 16.16 fractional scaling values, without any
*   further modification, and both `horiResolution` and `vertResolution`
*   are ignored.
*/
FT_Size_RequestRec_ :: struct {
    type:           FT_Size_Request_Type;
    width:          FT_Long;
    height:         FT_Long;
    horiResolution: FT_UInt;
    vertResolution: FT_UInt;
}

/**************************************************************************
*
* @struct:
*   FT_Size_RequestRec
*
* @description:
*   A structure to model a size request.
*
* @fields:
*   type ::
*     See @FT_Size_Request_Type.
*
*   width ::
*     The desired width, given as a 26.6 fractional point value (with 72pt
*     = 1in).
*
*   height ::
*     The desired height, given as a 26.6 fractional point value (with
*     72pt = 1in).
*
*   horiResolution ::
*     The horizontal resolution (dpi, i.e., pixels per inch).  If set to
*     zero, `width` is treated as a 26.6 fractional **pixel** value, which
*     gets internally rounded to an integer.
*
*   vertResolution ::
*     The vertical resolution (dpi, i.e., pixels per inch).  If set to
*     zero, `height` is treated as a 26.6 fractional **pixel** value,
*     which gets internally rounded to an integer.
*
* @note:
*   If `width` is zero, the horizontal scaling value is set equal to the
*   vertical scaling value, and vice versa.
*
*   If `type` is `FT_SIZE_REQUEST_TYPE_SCALES`, `width` and `height` are
*   interpreted directly as 16.16 fractional scaling values, without any
*   further modification, and both `horiResolution` and `vertResolution`
*   are ignored.
*/
FT_Size_RequestRec :: FT_Size_RequestRec_;

/**************************************************************************
*
* @struct:
*   FT_Size_Request
*
* @description:
*   A handle to a size request structure.
*/
FT_Size_Request :: *FT_Size_RequestRec_;

/**************************************************************************
*
* @function:
*   FT_Request_Size
*
* @description:
*   Resize the scale of the active @FT_Size object in a face.
*
* @inout:
*   face ::
*     A handle to a target face object.
*
* @input:
*   req ::
*     A pointer to a @FT_Size_RequestRec.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   Although drivers may select the bitmap strike matching the request,
*   you should not rely on this if you intend to select a particular
*   bitmap strike.  Use @FT_Select_Size instead in that case.
*
*   The relation between the requested size and the resulting glyph size
*   is dependent entirely on how the size is defined in the source face.
*   The font designer chooses the final size of each glyph relative to
*   this size.  For more information refer to
*   'https://freetype.org/freetype2/docs/glyphs/glyphs-2.html'.
*
*   Contrary to @FT_Set_Char_Size, this function doesn't have special code
*   to normalize zero-valued widths, heights, or resolutions, which are
*   treated as @FT_LOAD_NO_SCALE.
*
*   Don't use this function if you are using the FreeType cache API.
*/
FT_Request_Size :: (face: FT_Face, req: FT_Size_Request) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Char_Size
*
* @description:
*   Call @FT_Request_Size to request the nominal size (in points).
*
* @inout:
*   face ::
*     A handle to a target face object.
*
* @input:
*   char_width ::
*     The nominal width, in 26.6 fractional points.
*
*   char_height ::
*     The nominal height, in 26.6 fractional points.
*
*   horz_resolution ::
*     The horizontal resolution in dpi.
*
*   vert_resolution ::
*     The vertical resolution in dpi.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   While this function allows fractional points as input values, the
*   resulting ppem value for the given resolution is always rounded to the
*   nearest integer.
*
*   If either the character width or height is zero, it is set equal to
*   the other value.
*
*   If either the horizontal or vertical resolution is zero, it is set
*   equal to the other value.
*
*   A character width or height smaller than 1pt is set to 1pt; if both
*   resolution values are zero, they are set to 72dpi.
*
*   Don't use this function if you are using the FreeType cache API.
*/
FT_Set_Char_Size :: (face: FT_Face, char_width: FT_F26Dot6, char_height: FT_F26Dot6, horz_resolution: FT_UInt, vert_resolution: FT_UInt) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Pixel_Sizes
*
* @description:
*   Call @FT_Request_Size to request the nominal size (in pixels).
*
* @inout:
*   face ::
*     A handle to the target face object.
*
* @input:
*   pixel_width ::
*     The nominal width, in pixels.
*
*   pixel_height ::
*     The nominal height, in pixels.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   You should not rely on the resulting glyphs matching or being
*   constrained to this pixel size.  Refer to @FT_Request_Size to
*   understand how requested sizes relate to actual sizes.
*
*   Don't use this function if you are using the FreeType cache API.
*/
FT_Set_Pixel_Sizes :: (face: FT_Face, pixel_width: FT_UInt, pixel_height: FT_UInt) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Load_Glyph
*
* @description:
*   Load a glyph into the glyph slot of a face object.
*
* @inout:
*   face ::
*     A handle to the target face object where the glyph is loaded.
*
* @input:
*   glyph_index ::
*     The index of the glyph in the font file.  For CID-keyed fonts
*     (either in PS or in CFF format) this argument specifies the CID
*     value.
*
*   load_flags ::
*     A flag indicating what to load for this glyph.  The @FT_LOAD_XXX
*     flags can be used to control the glyph loading process (e.g.,
*     whether the outline should be scaled, whether to load bitmaps or
*     not, whether to hint the outline, etc).
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   For proper scaling and hinting, the active @FT_Size object owned by
*   the face has to be meaningfully initialized by calling
*   @FT_Set_Char_Size before this function, for example.  The loaded
*   glyph may be transformed.  See @FT_Set_Transform for the details.
*
*   For subsetted CID-keyed fonts, `FT_Err_Invalid_Argument` is returned
*   for invalid CID values (that is, for CID values that don't have a
*   corresponding glyph in the font).  See the discussion of the
*   @FT_FACE_FLAG_CID_KEYED flag for more details.
*
*   If you receive `FT_Err_Glyph_Too_Big`, try getting the glyph outline
*   at EM size, then scale it manually and fill it as a graphics
*   operation.
*/
FT_Load_Glyph :: (face: FT_Face, glyph_index: FT_UInt, load_flags: FT_Int32) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Load_Char
*
* @description:
*   Load a glyph into the glyph slot of a face object, accessed by its
*   character code.
*
* @inout:
*   face ::
*     A handle to a target face object where the glyph is loaded.
*
* @input:
*   char_code ::
*     The glyph's character code, according to the current charmap used in
*     the face.
*
*   load_flags ::
*     A flag indicating what to load for this glyph.  The @FT_LOAD_XXX
*     constants can be used to control the glyph loading process (e.g.,
*     whether the outline should be scaled, whether to load bitmaps or
*     not, whether to hint the outline, etc).
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   This function simply calls @FT_Get_Char_Index and @FT_Load_Glyph.
*
*   Many fonts contain glyphs that can't be loaded by this function since
*   its glyph indices are not listed in any of the font's charmaps.
*
*   If no active cmap is set up (i.e., `face->charmap` is zero), the call
*   to @FT_Get_Char_Index is omitted, and the function behaves identically
*   to @FT_Load_Glyph.
*/
FT_Load_Char :: (face: FT_Face, char_code: FT_ULong, load_flags: FT_Int32) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Transform
*
* @description:
*   Set the transformation that is applied to glyph images when they are
*   loaded into a glyph slot through @FT_Load_Glyph.
*
* @inout:
*   face ::
*     A handle to the source face object.
*
* @input:
*   matrix ::
*     A pointer to the transformation's 2x2 matrix.  Use `NULL` for the
*     identity matrix.
*   delta ::
*     A pointer to the translation vector.  Use `NULL` for the null
*     vector.
*
* @note:
*   This function is provided as a convenience, but keep in mind that
*   @FT_Matrix coefficients are only 16.16 fixed-point values, which can
*   limit the accuracy of the results.  Using floating-point computations
*   to perform the transform directly in client code instead will always
*   yield better numbers.
*
*   The transformation is only applied to scalable image formats after the
*   glyph has been loaded.  It means that hinting is unaltered by the
*   transformation and is performed on the character size given in the
*   last call to @FT_Set_Char_Size or @FT_Set_Pixel_Sizes.
*
*   Note that this also transforms the `face.glyph.advance` field, but
*   **not** the values in `face.glyph.metrics`.
*/
FT_Set_Transform :: (face: FT_Face, matrix: *FT_Matrix, delta: *FT_Vector) -> void #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Transform
*
* @description:
*   Return the transformation that is applied to glyph images when they
*   are loaded into a glyph slot through @FT_Load_Glyph.  See
*   @FT_Set_Transform for more details.
*
* @input:
*   face ::
*     A handle to the source face object.
*
* @output:
*   matrix ::
*     A pointer to a transformation's 2x2 matrix.  Set this to NULL if you
*     are not interested in the value.
*
*   delta ::
*     A pointer to a translation vector.  Set this to NULL if you are not
*     interested in the value.
*
* @since:
*   2.11
*
*/
FT_Get_Transform :: (face: FT_Face, matrix: *FT_Matrix, delta: *FT_Vector) -> void #foreign freetype;

/**************************************************************************
*
* @enum:
*   FT_Render_Mode
*
* @description:
*   Render modes supported by FreeType~2.  Each mode corresponds to a
*   specific type of scanline conversion performed on the outline.
*
*   For bitmap fonts and embedded bitmaps the `bitmap->pixel_mode` field
*   in the @FT_GlyphSlotRec structure gives the format of the returned
*   bitmap.
*
*   All modes except @FT_RENDER_MODE_MONO use 256 levels of opacity,
*   indicating pixel coverage.  Use linear alpha blending and gamma
*   correction to correctly render non-monochrome glyph bitmaps onto a
*   surface; see @FT_Render_Glyph.
*
*   The @FT_RENDER_MODE_SDF is a special render mode that uses up to 256
*   distance values, indicating the signed distance from the grid position
*   to the nearest outline.
*
* @values:
*   FT_RENDER_MODE_NORMAL ::
*     Default render mode; it corresponds to 8-bit anti-aliased bitmaps.
*
*   FT_RENDER_MODE_LIGHT ::
*     This is equivalent to @FT_RENDER_MODE_NORMAL.  It is only defined as
*     a separate value because render modes are also used indirectly to
*     define hinting algorithm selectors.  See @FT_LOAD_TARGET_XXX for
*     details.
*
*   FT_RENDER_MODE_MONO ::
*     This mode corresponds to 1-bit bitmaps (with 2~levels of opacity).
*
*   FT_RENDER_MODE_LCD ::
*     This mode corresponds to horizontal RGB and BGR subpixel displays
*     like LCD screens.  It produces 8-bit bitmaps that are 3~times the
*     width of the original glyph outline in pixels, and which use the
*     @FT_PIXEL_MODE_LCD mode.
*
*   FT_RENDER_MODE_LCD_V ::
*     This mode corresponds to vertical RGB and BGR subpixel displays
*     (like PDA screens, rotated LCD displays, etc.).  It produces 8-bit
*     bitmaps that are 3~times the height of the original glyph outline in
*     pixels and use the @FT_PIXEL_MODE_LCD_V mode.
*
*   FT_RENDER_MODE_SDF ::
*     The positive (unsigned) 8-bit bitmap values can be converted to the
*     single-channel signed distance field (SDF) by subtracting 128, with
*     the positive and negative results corresponding to the inside and
*     the outside of a glyph contour, respectively.  The distance units are
*     arbitrarily determined by an adjustable @spread property.
*
* @note:
*   The selected render mode only affects scalable vector glyphs of a font.
*   Embedded bitmaps often have a different pixel mode like
*   @FT_PIXEL_MODE_MONO.  You can use @FT_Bitmap_Convert to transform them
*   into 8-bit pixmaps.
*
*/
FT_Render_Mode_ :: enum u32 {
    NORMAL :: 0;
    LIGHT  :: 1;
    MONO   :: 2;
    LCD    :: 3;
    LCD_V  :: 4;
    SDF    :: 5;

    MAX    :: 6;

    FT_RENDER_MODE_NORMAL :: NORMAL;
    FT_RENDER_MODE_LIGHT  :: LIGHT;
    FT_RENDER_MODE_MONO   :: MONO;
    FT_RENDER_MODE_LCD    :: LCD;
    FT_RENDER_MODE_LCD_V  :: LCD_V;
    FT_RENDER_MODE_SDF    :: SDF;

    FT_RENDER_MODE_MAX    :: MAX;
}

/**************************************************************************
*
* @enum:
*   FT_Render_Mode
*
* @description:
*   Render modes supported by FreeType~2.  Each mode corresponds to a
*   specific type of scanline conversion performed on the outline.
*
*   For bitmap fonts and embedded bitmaps the `bitmap->pixel_mode` field
*   in the @FT_GlyphSlotRec structure gives the format of the returned
*   bitmap.
*
*   All modes except @FT_RENDER_MODE_MONO use 256 levels of opacity,
*   indicating pixel coverage.  Use linear alpha blending and gamma
*   correction to correctly render non-monochrome glyph bitmaps onto a
*   surface; see @FT_Render_Glyph.
*
*   The @FT_RENDER_MODE_SDF is a special render mode that uses up to 256
*   distance values, indicating the signed distance from the grid position
*   to the nearest outline.
*
* @values:
*   FT_RENDER_MODE_NORMAL ::
*     Default render mode; it corresponds to 8-bit anti-aliased bitmaps.
*
*   FT_RENDER_MODE_LIGHT ::
*     This is equivalent to @FT_RENDER_MODE_NORMAL.  It is only defined as
*     a separate value because render modes are also used indirectly to
*     define hinting algorithm selectors.  See @FT_LOAD_TARGET_XXX for
*     details.
*
*   FT_RENDER_MODE_MONO ::
*     This mode corresponds to 1-bit bitmaps (with 2~levels of opacity).
*
*   FT_RENDER_MODE_LCD ::
*     This mode corresponds to horizontal RGB and BGR subpixel displays
*     like LCD screens.  It produces 8-bit bitmaps that are 3~times the
*     width of the original glyph outline in pixels, and which use the
*     @FT_PIXEL_MODE_LCD mode.
*
*   FT_RENDER_MODE_LCD_V ::
*     This mode corresponds to vertical RGB and BGR subpixel displays
*     (like PDA screens, rotated LCD displays, etc.).  It produces 8-bit
*     bitmaps that are 3~times the height of the original glyph outline in
*     pixels and use the @FT_PIXEL_MODE_LCD_V mode.
*
*   FT_RENDER_MODE_SDF ::
*     The positive (unsigned) 8-bit bitmap values can be converted to the
*     single-channel signed distance field (SDF) by subtracting 128, with
*     the positive and negative results corresponding to the inside and
*     the outside of a glyph contour, respectively.  The distance units are
*     arbitrarily determined by an adjustable @spread property.
*
* @note:
*   The selected render mode only affects scalable vector glyphs of a font.
*   Embedded bitmaps often have a different pixel mode like
*   @FT_PIXEL_MODE_MONO.  You can use @FT_Bitmap_Convert to transform them
*   into 8-bit pixmaps.
*
*/
FT_Render_Mode :: FT_Render_Mode_;

/**************************************************************************
*
* @function:
*   FT_Render_Glyph
*
* @description:
*   Convert a given glyph image to a bitmap.  It does so by inspecting the
*   glyph image format, finding the relevant renderer, and invoking it.
*
* @inout:
*   slot ::
*     A handle to the glyph slot containing the image to convert.
*
* @input:
*   render_mode ::
*     The render mode used to render the glyph image into a bitmap.  See
*     @FT_Render_Mode for a list of possible values.
*
*     If @FT_RENDER_MODE_NORMAL is used, a previous call of @FT_Load_Glyph
*     with flag @FT_LOAD_COLOR makes `FT_Render_Glyph` provide a default
*     blending of colored glyph layers associated with the current glyph
*     slot (provided the font contains such layers) instead of rendering
*     the glyph slot's outline.  This is an experimental feature; see
*     @FT_LOAD_COLOR for more information.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   When FreeType outputs a bitmap of a glyph, it really outputs an alpha
*   coverage map.  If a pixel is completely covered by a filled-in
*   outline, the bitmap contains 0xFF at that pixel, meaning that
*   0xFF/0xFF fraction of that pixel is covered, meaning the pixel is 100%
*   black (or 0% bright).  If a pixel is only 50% covered (value 0x80),
*   the pixel is made 50% black (50% bright or a middle shade of grey).
*   0% covered means 0% black (100% bright or white).
*
*   On high-DPI screens like on smartphones and tablets, the pixels are so
*   small that their chance of being completely covered and therefore
*   completely black are fairly good.  On the low-DPI screens, however,
*   the situation is different.  The pixels are too large for most of the
*   details of a glyph and shades of gray are the norm rather than the
*   exception.
*
*   This is relevant because all our screens have a second problem: they
*   are not linear.  1~+~1 is not~2.  Twice the value does not result in
*   twice the brightness.  When a pixel is only 50% covered, the coverage
*   map says 50% black, and this translates to a pixel value of 128 when
*   you use 8~bits per channel (0-255).  However, this does not translate
*   to 50% brightness for that pixel on our sRGB and gamma~2.2 screens.
*   Due to their non-linearity, they dwell longer in the darks and only a
*   pixel value of about 186 results in 50% brightness -- 128 ends up too
*   dark on both bright and dark backgrounds.  The net result is that dark
*   text looks burnt-out, pixely and blotchy on bright background, bright
*   text too frail on dark backgrounds, and colored text on colored
*   background (for example, red on green) seems to have dark halos or
*   'dirt' around it.  The situation is especially ugly for diagonal stems
*   like in 'w' glyph shapes where the quality of FreeType's anti-aliasing
*   depends on the correct display of grays.  On high-DPI screens where
*   smaller, fully black pixels reign supreme, this doesn't matter, but on
*   our low-DPI screens with all the gray shades, it does.  0% and 100%
*   brightness are the same things in linear and non-linear space, just
*   all the shades in-between aren't.
*
*   The blending function for placing text over a background is
*
*   ```
*     dst = alpha * src + (1 - alpha) * dst    ,
*   ```
*
*   which is known as the OVER operator.
*
*   To correctly composite an anti-aliased pixel of a glyph onto a
*   surface,
*
*   1. take the foreground and background colors (e.g., in sRGB space)
*      and apply gamma to get them in a linear space,
*
*   2. use OVER to blend the two linear colors using the glyph pixel
*      as the alpha value (remember, the glyph bitmap is an alpha coverage
*      bitmap), and
*
*   3. apply inverse gamma to the blended pixel and write it back to
*      the image.
*
*   Internal testing at Adobe found that a target inverse gamma of~1.8 for
*   step~3 gives good results across a wide range of displays with an sRGB
*   gamma curve or a similar one.
*
*   This process can cost performance.  There is an approximation that
*   does not need to know about the background color; see
*   https://web.archive.org/web/20211019204945/https://bel.fi/alankila/lcd/
*   and
*   https://web.archive.org/web/20210211002939/https://bel.fi/alankila/lcd/alpcor.html
*   for details.
*
*   **ATTENTION**: Linear blending is even more important when dealing
*   with subpixel-rendered glyphs to prevent color-fringing!  A
*   subpixel-rendered glyph must first be filtered with a filter that
*   gives equal weight to the three color primaries and does not exceed a
*   sum of 0x100, see section @lcd_rendering.  Then the only difference to
*   gray linear blending is that subpixel-rendered linear blending is done
*   3~times per pixel: red foreground subpixel to red background subpixel
*   and so on for green and blue.
*/
FT_Render_Glyph :: (slot: FT_GlyphSlot, render_mode: FT_Render_Mode) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @enum:
*   FT_Kerning_Mode
*
* @description:
*   An enumeration to specify the format of kerning values returned by
*   @FT_Get_Kerning.
*
* @values:
*   FT_KERNING_DEFAULT ::
*     Return grid-fitted kerning distances in 26.6 fractional pixels.
*
*   FT_KERNING_UNFITTED ::
*     Return un-grid-fitted kerning distances in 26.6 fractional pixels.
*
*   FT_KERNING_UNSCALED ::
*     Return the kerning vector in original font units.
*
* @note:
*   `FT_KERNING_DEFAULT` returns full pixel values; it also makes FreeType
*   heuristically scale down kerning distances at small ppem values so
*   that they don't become too big.
*
*   Both `FT_KERNING_DEFAULT` and `FT_KERNING_UNFITTED` use the current
*   horizontal scaling factor (as set e.g. with @FT_Set_Char_Size) to
*   convert font units to pixels.
*/
FT_Kerning_Mode_ :: enum u32 {
    DEFAULT  :: 0;
    UNFITTED :: 1;
    UNSCALED :: 2;

    FT_KERNING_DEFAULT  :: DEFAULT;
    FT_KERNING_UNFITTED :: UNFITTED;
    FT_KERNING_UNSCALED :: UNSCALED;
}

/**************************************************************************
*
* @enum:
*   FT_Kerning_Mode
*
* @description:
*   An enumeration to specify the format of kerning values returned by
*   @FT_Get_Kerning.
*
* @values:
*   FT_KERNING_DEFAULT ::
*     Return grid-fitted kerning distances in 26.6 fractional pixels.
*
*   FT_KERNING_UNFITTED ::
*     Return un-grid-fitted kerning distances in 26.6 fractional pixels.
*
*   FT_KERNING_UNSCALED ::
*     Return the kerning vector in original font units.
*
* @note:
*   `FT_KERNING_DEFAULT` returns full pixel values; it also makes FreeType
*   heuristically scale down kerning distances at small ppem values so
*   that they don't become too big.
*
*   Both `FT_KERNING_DEFAULT` and `FT_KERNING_UNFITTED` use the current
*   horizontal scaling factor (as set e.g. with @FT_Set_Char_Size) to
*   convert font units to pixels.
*/
FT_Kerning_Mode :: FT_Kerning_Mode_;

/**************************************************************************
*
* @function:
*   FT_Get_Kerning
*
* @description:
*   Return the kerning vector between two glyphs of the same face.
*
* @input:
*   face ::
*     A handle to a source face object.
*
*   left_glyph ::
*     The index of the left glyph in the kern pair.
*
*   right_glyph ::
*     The index of the right glyph in the kern pair.
*
*   kern_mode ::
*     See @FT_Kerning_Mode for more information.  Determines the scale and
*     dimension of the returned kerning vector.
*
* @output:
*   akerning ::
*     The kerning vector.  This is either in font units, fractional pixels
*     (26.6 format), or pixels for scalable formats, and in pixels for
*     fixed-sizes formats.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   Only horizontal layouts (left-to-right & right-to-left) are supported
*   by this method.  Other layouts, or more sophisticated kernings, are
*   out of the scope of this API function -- they can be implemented
*   through format-specific interfaces.
*
*   Note that, for TrueType and OpenType fonts only, this can extract data
*   from both the 'kern' table and the basic, pair-wise kerning feature
*   from the GPOS table (with `TT_CONFIG_OPTION_GPOS_KERNING` enabled),
*   though FreeType does not support the more advanced GPOS layout
*   features; use a library like HarfBuzz for those instead.  If a font
*   has both a 'kern' table and kern features of a GPOS table, the 'kern'
*   table will be used.
*
*   Also note for right-to-left scripts, the functionality may differ for
*   fonts with GPOS tables vs. 'kern' tables.  For GPOS, right-to-left
*   fonts typically use both a placement offset and an advance for pair
*   positioning, which this API does not support, so it would output
*   kerning values of zero; though if the right-to-left font used only
*   advances in GPOS pair positioning, then this API could output kerning
*   values for it, but it would use `left_glyph` to mean the first glyph
*   for that case.  Whereas 'kern' tables are always advance-only and
*   always store the left glyph first.
*
*   Use @FT_HAS_KERNING to find out whether a font has data that can be
*   extracted with `FT_Get_Kerning`.
*/
FT_Get_Kerning :: (face: FT_Face, left_glyph: FT_UInt, right_glyph: FT_UInt, kern_mode: FT_UInt, akerning: *FT_Vector) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Track_Kerning
*
* @description:
*   Return the track kerning for a given face object at a given size.
*
* @input:
*   face ::
*     A handle to a source face object.
*
*   point_size ::
*     The point size in 16.16 fractional points.
*
*   degree ::
*     The degree of tightness.  Increasingly negative values represent
*     tighter track kerning, while increasingly positive values represent
*     looser track kerning.  Value zero means no track kerning.
*
* @output:
*   akerning ::
*     The kerning in 16.16 fractional points, to be uniformly applied
*     between all glyphs.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   Currently, only the Type~1 font driver supports track kerning, using
*   data from AFM files (if attached with @FT_Attach_File or
*   @FT_Attach_Stream).
*
*   Only very few AFM files come with track kerning data; please refer to
*   Adobe's AFM specification for more details.
*/
FT_Get_Track_Kerning :: (face: FT_Face, point_size: FT_Fixed, degree: FT_Int, akerning: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Select_Charmap
*
* @description:
*   Select a given charmap by its encoding tag (as listed in
*   `freetype.h`).
*
* @inout:
*   face ::
*     A handle to the source face object.
*
* @input:
*   encoding ::
*     A handle to the selected encoding.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   This function returns an error if no charmap in the face corresponds
*   to the encoding queried here.
*
*   Because many fonts contain more than a single cmap for Unicode
*   encoding, this function has some special code to select the one that
*   covers Unicode best ('best' in the sense that a UCS-4 cmap is
*   preferred to a UCS-2 cmap).  It is thus preferable to @FT_Set_Charmap
*   in this case.
*/
FT_Select_Charmap :: (face: FT_Face, encoding: FT_Encoding) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Charmap
*
* @description:
*   Select a given charmap for character code to glyph index mapping.
*
* @inout:
*   face ::
*     A handle to the source face object.
*
* @input:
*   charmap ::
*     A handle to the selected charmap.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   This function returns an error if the charmap is not part of the face
*   (i.e., if it is not listed in the `face->charmaps` table).
*
*   It also fails if an OpenType type~14 charmap is selected (which
*   doesn't map character codes to glyph indices at all).
*/
FT_Set_Charmap :: (face: FT_Face, charmap: FT_CharMap) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Charmap_Index
*
* @description:
*   Retrieve index of a given charmap.
*
* @input:
*   charmap ::
*     A handle to a charmap.
*
* @return:
*   The index into the array of character maps within the face to which
*   `charmap` belongs.  If an error occurs, -1 is returned.
*
*/
FT_Get_Charmap_Index :: (charmap: FT_CharMap) -> FT_Int #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Char_Index
*
* @description:
*   Return the glyph index of a given character code.  This function uses
*   the currently selected charmap to do the mapping.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   charcode ::
*     The character code.
*
* @return:
*   The glyph index.  0~means 'undefined character code'.
*
* @note:
*   If you use FreeType to manipulate the contents of font files directly,
*   be aware that the glyph index returned by this function doesn't always
*   correspond to the internal indices used within the file.  This is done
*   to ensure that value~0 always corresponds to the 'missing glyph'.  If
*   the first glyph is not named '.notdef', then for Type~1 and Type~42
*   fonts, '.notdef' will be moved into the glyph ID~0 position, and
*   whatever was there will be moved to the position '.notdef' had.  For
*   Type~1 fonts, if there is no '.notdef' glyph at all, then one will be
*   created at index~0 and whatever was there will be moved to the last
*   index -- Type~42 fonts are considered invalid under this condition.
*/
FT_Get_Char_Index :: (face: FT_Face, charcode: FT_ULong) -> FT_UInt #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_First_Char
*
* @description:
*   Return the first character code in the current charmap of a given
*   face, together with its corresponding glyph index.
*
* @input:
*   face ::
*     A handle to the source face object.
*
* @output:
*   agindex ::
*     Glyph index of first character code.  0~if charmap is empty.
*
* @return:
*   The charmap's first character code.
*
* @note:
*   You should use this function together with @FT_Get_Next_Char to parse
*   all character codes available in a given charmap.  The code should
*   look like this:
*
*   ```
*     FT_ULong  charcode;
*     FT_UInt   gindex;
*
*
*     charcode = FT_Get_First_Char( face, &gindex );
*     while ( gindex != 0 )
*     {
*       ... do something with (charcode,gindex) pair ...
*
*       charcode = FT_Get_Next_Char( face, charcode, &gindex );
*     }
*   ```
*
*   Be aware that character codes can have values up to 0xFFFFFFFF; this
*   might happen for non-Unicode or malformed cmaps.  However, even with
*   regular Unicode encoding, so-called 'last resort fonts' (using SFNT
*   cmap format 13, see function @FT_Get_CMap_Format) normally have
*   entries for all Unicode characters up to 0x1FFFFF, which can cause *a
*   lot* of iterations.
*
*   Note that `*agindex` is set to~0 if the charmap is empty.  The result
*   itself can be~0 in two cases: if the charmap is empty or if the
*   value~0 is the first valid character code.
*/
FT_Get_First_Char :: (face: FT_Face, agindex: *FT_UInt) -> FT_ULong #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Next_Char
*
* @description:
*   Return the next character code in the current charmap of a given face
*   following the value `char_code`, as well as the corresponding glyph
*   index.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   char_code ::
*     The starting character code.
*
* @output:
*   agindex ::
*     Glyph index of next character code.  0~if charmap is empty.
*
* @return:
*   The charmap's next character code.
*
* @note:
*   You should use this function with @FT_Get_First_Char to walk over all
*   character codes available in a given charmap.  See the note for that
*   function for a simple code example.
*
*   Note that `*agindex` is set to~0 when there are no more codes in the
*   charmap.
*/
FT_Get_Next_Char :: (face: FT_Face, char_code: FT_ULong, agindex: *FT_UInt) -> FT_ULong #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Face_Properties
*
* @description:
*   Set or override certain (library or module-wide) properties on a
*   face-by-face basis.  Useful for finer-grained control and avoiding
*   locks on shared structures (threads can modify their own faces as they
*   see fit).
*
*   Contrary to @FT_Property_Set, this function uses @FT_Parameter so that
*   you can pass multiple properties to the target face in one call.  Note
*   that only a subset of the available properties can be controlled.
*
*   * @FT_PARAM_TAG_STEM_DARKENING (stem darkening, corresponding to the
*     property `no-stem-darkening` provided by the 'autofit', 'cff',
*     'type1', and 't1cid' modules; see @no-stem-darkening).
*
*   * @FT_PARAM_TAG_RANDOM_SEED (seed value for the CFF, Type~1, and CID
*     'random' operator, corresponding to the `random-seed` property
*     provided by the 'cff', 'type1', and 't1cid' modules; see
*     @random-seed).
*
*   * @FT_PARAM_TAG_LCD_FILTER_WEIGHTS (no longer supported).
*
*   Pass `NULL` as `data` in @FT_Parameter for a given tag to reset the
*   option and use the library or module default again.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   num_properties ::
*     The number of properties that follow.
*
*   properties ::
*     A handle to an @FT_Parameter array with `num_properties` elements.
*
* @return:
*   FreeType error code.  0~means success.
*
* @example:
*   Here is an example that sets three properties.  You must define
*   `FT_CONFIG_OPTION_SUBPIXEL_RENDERING` to make the LCD filter examples
*   work.
*
*   ```
*     FT_Parameter         property1;
*     FT_Bool              darken_stems = 1;
*
*     FT_Parameter         property2;
*     FT_Int32             random_seed = 314159265;
*
*     FT_Parameter         properties[2] = { property1,
*                                            property2 };
*
*
*     property1.tag  = FT_PARAM_TAG_STEM_DARKENING;
*     property1.data = &darken_stems;
*
*     property2.tag  = FT_PARAM_TAG_RANDOM_SEED;
*     property2.data = &random_seed;
*
*     FT_Face_Properties( face, 3, properties );
*   ```
*
*   The next example resets a single property to its default value.
*
*   ```
*     FT_Parameter  property;
*
*
*     property.tag  = FT_PARAM_TAG_STEM_DARKENING;
*     property.data = NULL;
*
*     FT_Face_Properties( face, 1, &property );
*   ```
*
* @since:
*   2.8
*
*/
FT_Face_Properties :: (face: FT_Face, num_properties: FT_UInt, properties: *FT_Parameter) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Name_Index
*
* @description:
*   Return the glyph index of a given glyph name.  This only works
*   for those faces where @FT_HAS_GLYPH_NAMES returns true.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   glyph_name ::
*     The glyph name.
*
* @return:
*   The glyph index.  0~means 'undefined character code'.
*
* @note:
*   Acceptable glyph names might come from the [Adobe Glyph
*   List](https://github.com/adobe-type-tools/agl-aglfn).  See
*   @FT_Get_Glyph_Name for the inverse functionality.
*
*   This function has limited capabilities if the config macro
*   `FT_CONFIG_OPTION_POSTSCRIPT_NAMES` is not defined in `ftoption.h`:
*   It then works only for fonts that actually embed glyph names (which
*   many recent OpenType fonts do not).
*/
FT_Get_Name_Index :: (face: FT_Face, glyph_name: *FT_String) -> FT_UInt #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Glyph_Name
*
* @description:
*   Retrieve the ASCII name of a given glyph in a face.  This only works
*   for those faces where @FT_HAS_GLYPH_NAMES returns true.
*
* @input:
*   face ::
*     A handle to a source face object.
*
*   glyph_index ::
*     The glyph index.
*
*   buffer_max ::
*     The maximum number of bytes available in the buffer.
*
* @output:
*   buffer ::
*     A pointer to a target buffer where the name is copied to.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   An error is returned if the face doesn't provide glyph names or if the
*   glyph index is invalid.  In all cases of failure, the first byte of
*   `buffer` is set to~0 to indicate an empty name.
*
*   The glyph name is truncated to fit within the buffer if it is too
*   long.  The returned string is always zero-terminated.
*
*   Be aware that FreeType reorders glyph indices internally so that glyph
*   index~0 always corresponds to the 'missing glyph' (called '.notdef').
*
*   This function has limited capabilities if the config macro
*   `FT_CONFIG_OPTION_POSTSCRIPT_NAMES` is not defined in `ftoption.h`:
*   It then works only for fonts that actually embed glyph names (which
*   many recent OpenType fonts do not).
*/
FT_Get_Glyph_Name :: (face: FT_Face, glyph_index: FT_UInt, buffer: FT_Pointer, buffer_max: FT_UInt) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Postscript_Name
*
* @description:
*   Retrieve the ASCII PostScript name of a given face, if available.
*   This only works with PostScript, TrueType, and OpenType fonts.
*
* @input:
*   face ::
*     A handle to the source face object.
*
* @return:
*   A pointer to the face's PostScript name.  `NULL` if unavailable.
*
* @note:
*   The returned pointer is owned by the face and is destroyed with it.
*
*   For variation fonts, this string changes if you select a different
*   instance, and you have to call `FT_Get_PostScript_Name` again to
*   retrieve it.  FreeType follows Adobe TechNote #5902, 'Generating
*   PostScript Names for Fonts Using OpenType Font Variations'.
*
*     https://download.macromedia.com/pub/developer/opentype/tech-notes/5902.AdobePSNameGeneration.html
*
*   [Since 2.9] Special PostScript names for named instances are only
*   returned if the named instance is set with @FT_Set_Named_Instance (and
*   the font has corresponding entries in its 'fvar' table or is the
*   default named instance).  If @FT_IS_VARIATION returns true, the
*   algorithmically derived PostScript name is provided, not looking up
*   special entries for named instances.
*/
FT_Get_Postscript_Name :: (face: FT_Face) -> *u8 #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_SubGlyph_Info
*
* @description:
*   Retrieve a description of a given subglyph.  Only use it if
*   `glyph->format` is @FT_GLYPH_FORMAT_COMPOSITE; an error is returned
*   otherwise.
*
* @input:
*   glyph ::
*     The source glyph slot.
*
*   sub_index ::
*     The index of the subglyph.  Must be less than
*     `glyph->num_subglyphs`.
*
* @output:
*   p_index ::
*     The glyph index of the subglyph.
*
*   p_flags ::
*     The subglyph flags, see @FT_SUBGLYPH_FLAG_XXX.
*
*   p_arg1 ::
*     The subglyph's first argument (if any).
*
*   p_arg2 ::
*     The subglyph's second argument (if any).
*
*   p_transform ::
*     The subglyph transformation (if any).
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   The values of `*p_arg1`, `*p_arg2`, and `*p_transform` must be
*   interpreted depending on the flags returned in `*p_flags`.  See the
*   OpenType specification for details.
*
*     https://learn.microsoft.com/typography/opentype/spec/glyf#composite-glyph-description
*
*/
FT_Get_SubGlyph_Info :: (glyph: FT_GlyphSlot, sub_index: FT_UInt, p_index: *FT_Int, p_flags: *FT_UInt, p_arg1: *FT_Int, p_arg2: *FT_Int, p_transform: *FT_Matrix) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Face_GetCharVariantIndex
*
* @description:
*   Return the glyph index of a given character code as modified by the
*   variation selector.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   charcode ::
*     The character code point in Unicode.
*
*   variantSelector ::
*     The Unicode code point of the variation selector.
*
* @return:
*   The glyph index.  0~means either 'undefined character code', or
*   'undefined selector code', or 'no variation selector cmap subtable',
*   or 'current CharMap is not Unicode'.
*
* @note:
*   If you use FreeType to manipulate the contents of font files directly,
*   be aware that the glyph index returned by this function doesn't always
*   correspond to the internal indices used within the file.  This is done
*   to ensure that value~0 always corresponds to the 'missing glyph'.
*
*   This function is only meaningful if
*     a) the font has a variation selector cmap sub table, and
*     b) the current charmap has a Unicode encoding.
*
* @since:
*   2.3.6
*
*/
FT_Face_GetCharVariantIndex :: (face: FT_Face, charcode: FT_ULong, variantSelector: FT_ULong) -> FT_UInt #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Face_GetCharVariantIsDefault
*
* @description:
*   Check whether this variation of this Unicode character is the one to
*   be found in the charmap.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   charcode ::
*     The character codepoint in Unicode.
*
*   variantSelector ::
*     The Unicode codepoint of the variation selector.
*
* @return:
*   1~if found in the standard (Unicode) cmap, 0~if found in the variation
*   selector cmap, or -1 if it is not a variation.
*
* @note:
*   This function is only meaningful if the font has a variation selector
*   cmap subtable.
*
* @since:
*   2.3.6
*
*/
FT_Face_GetCharVariantIsDefault :: (face: FT_Face, charcode: FT_ULong, variantSelector: FT_ULong) -> FT_Int #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Face_GetVariantSelectors
*
* @description:
*   Return a zero-terminated list of Unicode variation selectors found in
*   the font.
*
* @input:
*   face ::
*     A handle to the source face object.
*
* @return:
*   A pointer to an array of selector code points, or `NULL` if there is
*   no valid variation selector cmap subtable.
*
* @note:
*   The last item in the array is~0; the array is owned by the @FT_Face
*   object but can be overwritten or released on the next call to a
*   FreeType function.
*
* @since:
*   2.3.6
*
*/
FT_Face_GetVariantSelectors :: (face: FT_Face) -> *FT_UInt32 #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Face_GetVariantsOfChar
*
* @description:
*   Return a zero-terminated list of Unicode variation selectors found for
*   the specified character code.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   charcode ::
*     The character codepoint in Unicode.
*
* @return:
*   A pointer to an array of variation selector code points that are
*   active for the given character, or `NULL` if the corresponding list is
*   empty.
*
* @note:
*   The last item in the array is~0; the array is owned by the @FT_Face
*   object but can be overwritten or released on the next call to a
*   FreeType function.
*
* @since:
*   2.3.6
*
*/
FT_Face_GetVariantsOfChar :: (face: FT_Face, charcode: FT_ULong) -> *FT_UInt32 #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Face_GetCharsOfVariant
*
* @description:
*   Return a zero-terminated list of Unicode character codes found for the
*   specified variation selector.
*
* @input:
*   face ::
*     A handle to the source face object.
*
*   variantSelector ::
*     The variation selector code point in Unicode.
*
* @return:
*   A list of all the code points that are specified by this selector
*   (both default and non-default codes are returned) or `NULL` if there
*   is no valid cmap or the variation selector is invalid.
*
* @note:
*   The last item in the array is~0; the array is owned by the @FT_Face
*   object but can be overwritten or released on the next call to a
*   FreeType function.
*
* @since:
*   2.3.6
*
*/
FT_Face_GetCharsOfVariant :: (face: FT_Face, variantSelector: FT_ULong) -> *FT_UInt32 #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_MulDiv
*
* @description:
*   Compute `(a*b)/c` with maximum accuracy, using a 64-bit intermediate
*   integer whenever necessary.
*
*   This function isn't necessarily as fast as some processor-specific
*   operations, but is at least completely portable.
*
* @input:
*   a ::
*     The first multiplier.
*
*   b ::
*     The second multiplier.
*
*   c ::
*     The divisor.
*
* @return:
*   The result of `(a*b)/c`.  This function never traps when trying to
*   divide by zero; it simply returns 'MaxInt' or 'MinInt' depending on
*   the signs of `a` and `b`.
*/
FT_MulDiv :: (a: FT_Long, b: FT_Long, c: FT_Long) -> FT_Long #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_MulFix
*
* @description:
*   Compute `(a*b)/0x10000` with maximum accuracy.  Its main use is to
*   multiply a given value by a 16.16 fixed-point factor.
*
* @input:
*   a ::
*     The first multiplier.
*
*   b ::
*     The second multiplier.  Use a 16.16 factor here whenever possible
*     (see note below).
*
* @return:
*   The result of `(a*b)/0x10000`.
*
* @note:
*   This function has been optimized for the case where the absolute value
*   of `a` is less than 2048, and `b` is a 16.16 scaling factor.  As this
*   happens mainly when scaling from notional units to fractional pixels
*   in FreeType, it resulted in noticeable speed improvements between
*   versions 2.x and 1.x.
*
*   As a conclusion, always try to place a 16.16 factor as the _second_
*   argument of this function; this can make a great difference.
*/
FT_MulFix :: (a: FT_Long, b: FT_Long) -> FT_Long #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_DivFix
*
* @description:
*   Compute `(a*0x10000)/b` with maximum accuracy.  Its main use is to
*   divide a given value by a 16.16 fixed-point factor.
*
* @input:
*   a ::
*     The numerator.
*
*   b ::
*     The denominator.  Use a 16.16 factor here.
*
* @return:
*   The result of `(a*0x10000)/b`.
*/
FT_DivFix :: (a: FT_Long, b: FT_Long) -> FT_Long #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_RoundFix
*
* @description:
*   Round a 16.16 fixed number.
*
* @input:
*   a ::
*     The number to be rounded.
*
* @return:
*   `a` rounded to the nearest 16.16 fixed integer, halfway cases away
*   from zero.
*
* @note:
*   The function uses wrap-around arithmetic.
*/
FT_RoundFix :: (a: FT_Fixed) -> FT_Fixed #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_CeilFix
*
* @description:
*   Compute the smallest following integer of a 16.16 fixed number.
*
* @input:
*   a ::
*     The number for which the ceiling function is to be computed.
*
* @return:
*   `a` rounded towards plus infinity.
*
* @note:
*   The function uses wrap-around arithmetic.
*/
FT_CeilFix :: (a: FT_Fixed) -> FT_Fixed #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_FloorFix
*
* @description:
*   Compute the largest previous integer of a 16.16 fixed number.
*
* @input:
*   a ::
*     The number for which the floor function is to be computed.
*
* @return:
*   `a` rounded towards minus infinity.
*/
FT_FloorFix :: (a: FT_Fixed) -> FT_Fixed #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Vector_Transform
*
* @description:
*   Transform a single vector through a 2x2 matrix.
*
* @inout:
*   vector ::
*     The target vector to transform.
*
* @input:
*   matrix ::
*     A pointer to the source 2x2 matrix.
*
* @note:
*   The result is undefined if either `vector` or `matrix` is invalid.
*/
FT_Vector_Transform :: (vector: *FT_Vector, matrix: *FT_Matrix) -> void #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Library_Version
*
* @description:
*   Return the version of the FreeType library being used.  This is useful
*   when dynamically linking to the library, since one cannot use the
*   macros @FREETYPE_MAJOR, @FREETYPE_MINOR, and @FREETYPE_PATCH.
*
* @input:
*   library ::
*     A source library handle.
*
* @output:
*   amajor ::
*     The major version number.
*
*   aminor ::
*     The minor version number.
*
*   apatch ::
*     The patch version number.
*
* @note:
*   The reason why this function takes a `library` argument is because
*   certain programs implement library initialization in a custom way that
*   doesn't use @FT_Init_FreeType.
*
*   In such cases, the library version might not be available before the
*   library object has been created.
*/
FT_Library_Version :: (library: FT_Library, amajor: *FT_Int, aminor: *FT_Int, apatch: *FT_Int) -> void #foreign freetype;

/**************************************************************************
*
* @struct:
*   FT_MM_Axis
*
* @description:
*   A structure to model a given axis in design space for Adobe MM fonts.
*
*   This structure can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @fields:
*   name ::
*     The axis's name.
*
*   minimum ::
*     The axis's minimum design coordinate.
*
*   maximum ::
*     The axis's maximum design coordinate.
*/
FT_MM_Axis_ :: struct {
    name:    *FT_String;
    minimum: FT_Long;
    maximum: FT_Long;
}

/**************************************************************************
*
* @struct:
*   FT_MM_Axis
*
* @description:
*   A structure to model a given axis in design space for Adobe MM fonts.
*
*   This structure can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @fields:
*   name ::
*     The axis's name.
*
*   minimum ::
*     The axis's minimum design coordinate.
*
*   maximum ::
*     The axis's maximum design coordinate.
*/
FT_MM_Axis :: FT_MM_Axis_;

/**************************************************************************
*
* @struct:
*   FT_Multi_Master
*
* @description:
*   A structure to model the axes and space of an Adobe MM font.
*
*   This structure can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @fields:
*   num_axis ::
*     Number of axes.  Cannot exceed~4.
*
*   num_designs ::
*     Number of designs; should be normally `2^num_axis` even though the
*     Type~1 specification strangely allows for intermediate designs to be
*     present.  This number cannot exceed~16.
*
*   axis ::
*     A table of axis descriptors.
*/
FT_Multi_Master_ :: struct {
    num_axis:    FT_UInt;
    num_designs: FT_UInt;
    axis:        [4] FT_MM_Axis;
}

/**************************************************************************
*
* @struct:
*   FT_Multi_Master
*
* @description:
*   A structure to model the axes and space of an Adobe MM font.
*
*   This structure can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @fields:
*   num_axis ::
*     Number of axes.  Cannot exceed~4.
*
*   num_designs ::
*     Number of designs; should be normally `2^num_axis` even though the
*     Type~1 specification strangely allows for intermediate designs to be
*     present.  This number cannot exceed~16.
*
*   axis ::
*     A table of axis descriptors.
*/
FT_Multi_Master :: FT_Multi_Master_;

/**************************************************************************
*
* @struct:
*   FT_Var_Axis
*
* @description:
*   A structure to model a given axis in design space for Adobe MM fonts,
*   TrueType GX, and OpenType Font Variations.
*
* @fields:
*   name ::
*     The axis's name.  Not always meaningful for TrueType GX or OpenType
*     Font Variations.
*
*   minimum ::
*     The axis's minimum design coordinate.
*
*   def ::
*     The axis's default design coordinate.  FreeType computes meaningful
*     default values for Adobe MM fonts.
*
*   maximum ::
*     The axis's maximum design coordinate.
*
*   tag ::
*     The axis's tag (the equivalent to 'name' for TrueType GX and
*     OpenType Font Variations).  FreeType provides default values for
*     Adobe MM fonts if possible.
*
*   strid ::
*     The axis name entry in the font's 'name' table.  This is another
*     (and often better) version of the 'name' field for TrueType GX or
*     OpenType Font Variations.  Not meaningful for Adobe MM fonts.
*
* @note:
*   The fields `minimum`, `def`, and `maximum` are 16.16 fractional values
*   for TrueType GX and OpenType Font Variations.  For Adobe MM fonts, the
*   values are whole numbers (i.e., the fractional part is zero).
*/
FT_Var_Axis_ :: struct {
    name:    *FT_String;

    minimum: FT_Fixed;
    def:     FT_Fixed;
    maximum: FT_Fixed;

    tag:     FT_ULong;
    strid:   FT_UInt;
}

/**************************************************************************
*
* @struct:
*   FT_Var_Axis
*
* @description:
*   A structure to model a given axis in design space for Adobe MM fonts,
*   TrueType GX, and OpenType Font Variations.
*
* @fields:
*   name ::
*     The axis's name.  Not always meaningful for TrueType GX or OpenType
*     Font Variations.
*
*   minimum ::
*     The axis's minimum design coordinate.
*
*   def ::
*     The axis's default design coordinate.  FreeType computes meaningful
*     default values for Adobe MM fonts.
*
*   maximum ::
*     The axis's maximum design coordinate.
*
*   tag ::
*     The axis's tag (the equivalent to 'name' for TrueType GX and
*     OpenType Font Variations).  FreeType provides default values for
*     Adobe MM fonts if possible.
*
*   strid ::
*     The axis name entry in the font's 'name' table.  This is another
*     (and often better) version of the 'name' field for TrueType GX or
*     OpenType Font Variations.  Not meaningful for Adobe MM fonts.
*
* @note:
*   The fields `minimum`, `def`, and `maximum` are 16.16 fractional values
*   for TrueType GX and OpenType Font Variations.  For Adobe MM fonts, the
*   values are whole numbers (i.e., the fractional part is zero).
*/
FT_Var_Axis :: FT_Var_Axis_;

/**************************************************************************
*
* @struct:
*   FT_Var_Named_Style
*
* @description:
*   A structure to model a named instance in a TrueType GX or OpenType
*   Font Variations.
*
*   This structure can't be used for Adobe MM fonts.
*
* @fields:
*   coords ::
*     The design coordinates for this instance.  This is an array with one
*     entry for each axis.
*
*   strid ::
*     An index into the 'name' table identifying this instance.
*
*   psid ::
*     An index into the 'name' table identifying a PostScript name for
*     this instance.  Value 0xFFFF indicates a missing entry.
*/
FT_Var_Named_Style_ :: struct {
    coords: *FT_Fixed;
    strid:  FT_UInt;
    psid:   FT_UInt; /* since 2.7.1 */
}

/**************************************************************************
*
* @struct:
*   FT_Var_Named_Style
*
* @description:
*   A structure to model a named instance in a TrueType GX or OpenType
*   Font Variations.
*
*   This structure can't be used for Adobe MM fonts.
*
* @fields:
*   coords ::
*     The design coordinates for this instance.  This is an array with one
*     entry for each axis.
*
*   strid ::
*     An index into the 'name' table identifying this instance.
*
*   psid ::
*     An index into the 'name' table identifying a PostScript name for
*     this instance.  Value 0xFFFF indicates a missing entry.
*/
FT_Var_Named_Style :: FT_Var_Named_Style_;

/**************************************************************************
*
* @struct:
*   FT_MM_Var
*
* @description:
*   A structure to model the axes and space of Adobe MM fonts, TrueType
*   GX, or OpenType Font Variations.
*
*   Some fields are specific to one format and not to the others.
*
* @fields:
*   num_axis ::
*     The number of axes.  The maximum value is~4 for Adobe MM fonts; no
*     limit in TrueType GX or OpenType Font Variations.
*
*   num_designs ::
*     The number of designs; should be normally `2^num_axis` for Adobe MM
*     fonts.  Not meaningful for TrueType GX or OpenType Font Variations
*     (where every glyph could have a different number of designs).
*
*   num_namedstyles ::
*     The number of named instances.  For Adobe MM fonts, this value is
*     always zero.
*
*   axis ::
*     An axis descriptor table.  TrueType GX and OpenType Font Variations
*     contain slightly more data than Adobe MM fonts.  Memory management
*     of this pointer is done internally by FreeType.
*
*   namedstyle ::
*     An array of named instances.  Only meaningful for TrueType GX and
*     OpenType Font Variations.  Memory management of this pointer is done
*     internally by FreeType.
*/
FT_MM_Var_ :: struct {
    num_axis:        FT_UInt;
    num_designs:     FT_UInt;
    num_namedstyles: FT_UInt;
    axis:            *FT_Var_Axis;
    namedstyle:      *FT_Var_Named_Style;
}

/**************************************************************************
*
* @struct:
*   FT_MM_Var
*
* @description:
*   A structure to model the axes and space of Adobe MM fonts, TrueType
*   GX, or OpenType Font Variations.
*
*   Some fields are specific to one format and not to the others.
*
* @fields:
*   num_axis ::
*     The number of axes.  The maximum value is~4 for Adobe MM fonts; no
*     limit in TrueType GX or OpenType Font Variations.
*
*   num_designs ::
*     The number of designs; should be normally `2^num_axis` for Adobe MM
*     fonts.  Not meaningful for TrueType GX or OpenType Font Variations
*     (where every glyph could have a different number of designs).
*
*   num_namedstyles ::
*     The number of named instances.  For Adobe MM fonts, this value is
*     always zero.
*
*   axis ::
*     An axis descriptor table.  TrueType GX and OpenType Font Variations
*     contain slightly more data than Adobe MM fonts.  Memory management
*     of this pointer is done internally by FreeType.
*
*   namedstyle ::
*     An array of named instances.  Only meaningful for TrueType GX and
*     OpenType Font Variations.  Memory management of this pointer is done
*     internally by FreeType.
*/
FT_MM_Var :: FT_MM_Var_;

/**************************************************************************
*
* @function:
*   FT_Get_Multi_Master
*
* @description:
*   Retrieve a variation descriptor of a given Adobe MM font.
*
*   This function can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @input:
*   face ::
*     A handle to the source face.
*
* @output:
*   amaster ::
*     The Adobe MM font's variation descriptor.
*
* @return:
*   FreeType error code.  0~means success.
*/
FT_Get_Multi_Master :: (face: FT_Face, amaster: *FT_Multi_Master) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_MM_Var
*
* @description:
*   Retrieve a variation descriptor for a given font.
*
*   This function works with all supported variation formats.
*
* @input:
*   face ::
*     A handle to the source face.
*
* @output:
*   amaster ::
*     The variation descriptor.  Allocates a data structure, which the
*     user must deallocate with a call to @FT_Done_MM_Var after use.
*
* @return:
*   FreeType error code.  0~means success.
*/
FT_Get_MM_Var :: (face: FT_Face, amaster: **FT_MM_Var) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Done_MM_Var
*
* @description:
*   Free the memory allocated by @FT_Get_MM_Var.
*
* @input:
*   library ::
*     A handle of the face's parent library object that was used in the
*     call to @FT_Get_MM_Var to create `amaster`.
*
* @return:
*   FreeType error code.  0~means success.
*/
FT_Done_MM_Var :: (library: FT_Library, amaster: *FT_MM_Var) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_MM_Design_Coordinates
*
* @description:
*   For Adobe MM fonts, choose an interpolated font design through design
*   coordinates.
*
*   This function can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @inout:
*   face ::
*     A handle to the source face.
*
* @input:
*   num_coords ::
*     The number of available design coordinates.  If it is larger than
*     the number of axes, ignore the excess values.  If it is smaller than
*     the number of axes, use default values for the remaining axes.
*
*   coords ::
*     An array of design coordinates.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   [Since 2.8.1] To reset all axes to the default values, call the
*   function with `num_coords` set to zero and `coords` set to `NULL`.
*
*   [Since 2.9] If `num_coords` is larger than zero, this function sets
*   the @FT_FACE_FLAG_VARIATION bit in @FT_Face's `face_flags` field
*   (i.e., @FT_IS_VARIATION returns true).  If `num_coords` is zero, this
*   bit flag gets unset.
*/
FT_Set_MM_Design_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Long) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Var_Design_Coordinates
*
* @description:
*   Choose an interpolated font design through design coordinates.
*
*   This function works with all supported variation formats.
*
* @inout:
*   face ::
*     A handle to the source face.
*
* @input:
*   num_coords ::
*     The number of available design coordinates.  If it is larger than
*     the number of axes, ignore the excess values.  If it is smaller than
*     the number of axes, use default values for the remaining axes.
*
*   coords ::
*     An array of design coordinates.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   The design coordinates are 16.16 fractional values for TrueType GX and
*   OpenType Font Variations.  For Adobe MM fonts, the values are supposed
*   to be whole numbers (i.e., the fractional part is zero).
*
*   [Since 2.8.1] To reset all axes to the default values, call the
*   function with `num_coords` set to zero and `coords` set to `NULL`.
*   [Since 2.9] 'Default values' means the currently selected named
*   instance (or the base font if no named instance is selected).
*
*   [Since 2.9] If `num_coords` is larger than zero, this function sets
*   the @FT_FACE_FLAG_VARIATION bit in @FT_Face's `face_flags` field
*   (i.e., @FT_IS_VARIATION returns true).  If `num_coords` is zero, this
*   bit flag gets unset.
*
*   [Since 2.14] This function also sets the @FT_FACE_FLAG_VARIATION bit
*   in @FT_Face's `face_flags` field (i.e., @FT_IS_VARIATION returns
*   true) if any of the provided coordinates is different from the face's
*   default value for the corresponding axis, that is, the set up face is
*   not at its default position.
*/
FT_Set_Var_Design_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Var_Design_Coordinates
*
* @description:
*   Get the design coordinates of the currently selected interpolated
*   font.
*
*   This function works with all supported variation formats.
*
* @input:
*   face ::
*     A handle to the source face.
*
*   num_coords ::
*     The number of design coordinates to retrieve.  If it is larger than
*     the number of axes, set the excess values to~0.
*
* @output:
*   coords ::
*     The design coordinates array, which must be allocated by the user.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   The design coordinates are 16.16 fractional values for TrueType GX and
*   OpenType Font Variations.  For Adobe MM fonts, the values are whole
*   numbers (i.e., the fractional part is zero).
*
* @since:
*   2.7.1
*/
FT_Get_Var_Design_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_MM_Blend_Coordinates
*
* @description:
*   Choose an interpolated font design through normalized coordinates.
*
*   This function works with all supported variation formats.
*
* @inout:
*   face ::
*     A handle to the source face.
*
* @input:
*   num_coords ::
*     The number of available design coordinates.  If it is larger than
*     the number of axes, ignore the excess values.  If it is smaller than
*     the number of axes, use default values for the remaining axes.
*
*   coords ::
*     The normalized coordinates array.  Each element is a 16.16
*     fractional value and must be between 0 and 1.0 for Adobe MM fonts,
*     and between -1.0 and 1.0 for TrueType GX and OpenType Font
*     Variations.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   [Since 2.8.1] To reset all axes to the default values, call the
*   function with `num_coords` set to zero and `coords` set to `NULL`.
*   [Since 2.9] 'Default values' means the currently selected named
*   instance (or the base font if no named instance is selected).
*
*   [Since 2.9] If `num_coords` is larger than zero, this function sets
*   the @FT_FACE_FLAG_VARIATION bit in @FT_Face's `face_flags` field
*   (i.e., @FT_IS_VARIATION returns true).  If `num_coords` is zero, this
*   bit flag gets unset.
*
*   [Since 2.14] This function also sets the @FT_FACE_FLAG_VARIATION bit
*   in @FT_Face's `face_flags` field (i.e., @FT_IS_VARIATION returns
*   true) if any of the provided coordinates is different from the face's
*   default value for the corresponding axis, that is, the set up face is
*   not at its default position.
*/
FT_Set_MM_Blend_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_MM_Blend_Coordinates
*
* @description:
*   Get the normalized coordinates of the currently selected interpolated
*   font.
*
*   This function works with all supported variation formats.
*
* @input:
*   face ::
*     A handle to the source face.
*
*   num_coords ::
*     The number of normalized coordinates to retrieve.  If it is larger
*     than the number of axes, set the excess values to~0.5 for Adobe MM
*     fonts, and to~0 for TrueType GX and OpenType Font Variations.
*
* @output:
*   coords ::
*     The normalized coordinates array (as 16.16 fractional values), which
*     must be allocated by the user.
*
* @return:
*   FreeType error code.  0~means success.
*
* @since:
*   2.7.1
*/
FT_Get_MM_Blend_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Var_Blend_Coordinates
*
* @description:
*   This is another name of @FT_Set_MM_Blend_Coordinates.
*/
FT_Set_Var_Blend_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Var_Blend_Coordinates
*
* @description:
*   This is another name of @FT_Get_MM_Blend_Coordinates.
*
* @since:
*   2.7.1
*/
FT_Get_Var_Blend_Coordinates :: (face: FT_Face, num_coords: FT_UInt, coords: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_MM_WeightVector
*
* @description:
*   For Adobe MM fonts, choose an interpolated font design by directly
*   setting the weight vector.
*
*   This function can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @inout:
*   face ::
*     A handle to the source face.
*
* @input:
*   len ::
*     The length of the weight vector array.  If it is larger than the
*     number of designs, the extra values are ignored.  If it is less than
*     the number of designs, the remaining values are set to zero.
*
*   weightvector ::
*     An array representing the weight vector.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   Adobe MM fonts limit the number of designs, and thus the length of the
*   weight vector, to 16~elements.
*
*   If `len` is larger than zero, this function sets the
*   @FT_FACE_FLAG_VARIATION bit in @FT_Face's `face_flags` field (i.e.,
*   @FT_IS_VARIATION returns true).  If `len` is zero, this bit flag is
*   unset and the weight vector array is reset to the default values.
*
*   The Adobe documentation also states that the values in the
*   `WeightVector` array must total 1.0 +/-~0.001.  In practice this does
*   not seem to be enforced, so is not enforced here, either.
*
* @since:
*   2.10
*/
FT_Set_MM_WeightVector :: (face: FT_Face, len: FT_UInt, weightvector: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_MM_WeightVector
*
* @description:
*   For Adobe MM fonts, retrieve the current weight vector of the font.
*
*   This function can't be used with TrueType GX or OpenType Font
*   Variations.
*
* @inout:
*   face ::
*     A handle to the source face.
*
*   len ::
*     A pointer to the size of the array to be filled.  If the size of the
*     array is less than the number of designs, `FT_Err_Invalid_Argument`
*     is returned, and `len` is set to the required size (the number of
*     designs).  If the size of the array is greater than the number of
*     designs, the remaining entries are set to~0.  On successful
*     completion, `len` is set to the number of designs (i.e., the number
*     of values written to the array).
*
* @output:
*   weightvector ::
*     An array to be filled; it must be allocated by the user.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   Adobe MM fonts limit the number of designs, and thus the length of the
*   weight vector, to~16 elements.
*
* @since:
*   2.10
*/
FT_Get_MM_WeightVector :: (face: FT_Face, len: *FT_UInt, weightvector: *FT_Fixed) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Var_Axis_Flags
*
* @description:
*   Get the 'flags' field of an OpenType Variation Axis Record.
*
*   Not meaningful for Adobe MM fonts (`*flags` is always zero).
*
* @input:
*   master ::
*     The variation descriptor.
*
*   axis_index ::
*     The index of the requested variation axis.
*
* @output:
*   flags ::
*     The 'flags' field.  See @FT_VAR_AXIS_FLAG_XXX for possible values.
*
* @return:
*   FreeType error code.  0~means success.
*
* @since:
*   2.8.1
*/
FT_Get_Var_Axis_Flags :: (master: *FT_MM_Var, axis_index: FT_UInt, flags: *FT_UInt) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Set_Named_Instance
*
* @description:
*   Set or change the current named instance.
*
* @input:
*   face ::
*     A handle to the source face.
*
*   instance_index ::
*     The index of the requested instance, starting with value~1.  If set
*     to value~0, FreeType switches to font access without a named
*     instance.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   The function uses the value of `instance_index` to set bits 16-30 of
*   the face's `face_index` field.  It also resets any variation applied
*   to the font, and the @FT_FACE_FLAG_VARIATION bit of the face's
*   `face_flags` field gets reset to zero (i.e., @FT_IS_VARIATION returns
*   false).
*
*   For Adobe MM fonts, this function resets the current face to the
*   default instance.
*
* @since:
*   2.9
*/
FT_Set_Named_Instance :: (face: FT_Face, instance_index: FT_UInt) -> FT_Error #foreign freetype;

/**************************************************************************
*
* @function:
*   FT_Get_Default_Named_Instance
*
* @description:
*   Retrieve the index of the default named instance, to be used with
*   @FT_Set_Named_Instance.
*
*   FreeType synthesizes a named instance for the default instance if the
*   font does not contain such an entry.
*
* @input:
*   face ::
*     A handle to the source face.
*
* @output:
*   instance_index ::
*     The index of the default named instance.
*
* @return:
*   FreeType error code.  0~means success.
*
* @note:
*   For Adobe MM fonts, this function always returns zero for
*   `instance_index`.
*
* @since:
*   2.13.1
*/
FT_Get_Default_Named_Instance :: (face: FT_Face, instance_index: *FT_UInt) -> FT_Error #foreign freetype;

#scope_file


freetype :: #library,no_dll "vendor/freetype";
ptrdiff_t :: s64;

#scope_export
