
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
