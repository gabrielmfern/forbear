#include "node.h"
#include "uv.h"
#include "v8-isolate.h"
#include "v8-platform.h"
#include <cstdint>

extern "C" void forbear_open(void* adapter, void* style_object);
extern "C" void forbear_close(void* adapter);
extern "C" void forbear_text_push(void* adapter);

enum JavascriptStyleField : uint8_t {
    BACKGROUND, COLOR, BORDER_RADIUS, BORDER_COLOR, BORDER_WIDTH, BORDER_STYLE,
    SHADOW, FONT, FONT_WEIGHT, FONT_SIZE, LINE_HEIGHT, TEXT_WRAPPING, CURSOR,
    OVERFLOW, PLACEMENT, Z_INDEX, MIN_WIDTH, MAX_WIDTH, WIDTH, MIN_HEIGHT,
    MAX_HEIGHT, HEIGHT, TRANSLATE, PADDING, MARGIN, X_JUSTIFICATION,
    Y_JUSTIFICATION, DIRECTION,
};
static const char* style_field_names[] = {
    "background", "color", "borderRadius", "borderColor", "borderWidth", "borderStyle",
    "shadow", "font", "fontWeight", "fontSize", "lineHeight", "textWrapping", "cursor",
    "overflow", "placement", "zIndex", "minWidth", "maxWidth", "width", "minHeight",
    "maxHeight", "height", "translate", "padding", "margin", "xJustification", 
    "yJustification", "direction",
};

struct JavascriptRuntime {
    uv_loop_t* loop;
    std::unique_ptr<node::MultiIsolatePlatform> platform;
    node::ArrayBufferAllocator* allocator;
    v8::Isolate* isolate;
    v8::Global<v8::Context>* context;
    v8::Global<v8::String> property_names[DIRECTION + 1];
};

extern "C" void* javascript_init() {
    auto runtime = new JavascriptRuntime;

    // TODO: should we have this thread pool be configurable?
    runtime->platform = node::MultiIsolatePlatform::Create(1);
    auto platform = runtime->platform.get();
    v8::V8::InitializePlatform(platform);
    if (v8::V8::Initialize()) {
        runtime->loop = new uv_loop_t;
        if (uv_loop_init(runtime->loop) == 0) {
            runtime->allocator = node::CreateArrayBufferAllocator();
            runtime->isolate = node::NewIsolate(runtime->allocator, runtime->loop, platform);
            if (runtime->isolate) {
                v8::Isolate::Scope isolate_scope(runtime->isolate);
                v8::HandleScope handle_scope(runtime->isolate);
                runtime->context = new v8::Global<v8::Context>(runtime->isolate, node::NewContext(runtime->isolate));

                for (uint8_t field = 0; field <= DIRECTION; ++field) {
                    runtime->property_names[field].Reset(
                        runtime->isolate,
                        v8::String::NewFromUtf8(
                            runtime->isolate,
                            style_field_names[field],
                            v8::NewStringType::kInternalized
                        ).ToLocalChecked()
                    );
                }

                return (void*) runtime;
            }
        }
    }

    return nullptr;
}

// commented out since this is meant to run for the entire program's lifetime. we might want to bring it back in the future, so leave this here.
//
// extern "C" void javascript_destroy(void* runtime_opaque) {
//     auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
//     delete runtime->context;
//     runtime->context = nullptr;
//     for (auto& name : runtime->property_names) {
//         name.Reset();
//     }
//     runtime->platform->DisposeIsolate(runtime->isolate);
//     node::FreeArrayBufferAllocator(runtime->allocator);
//     uv_loop_close(runtime->loop);
//     delete runtime->loop;
//     delete runtime;
// }

extern "C" bool javascript_style_get_number(
    void* runtime_opaque,
    void* style_object,
    JavascriptStyleField field,
    double* result
) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BORDER_RADIUS: 
        case FONT_WEIGHT:
        case FONT_SIZE:
        case LINE_HEIGHT:
        case Z_INDEX:
        case MIN_WIDTH:
        case MIN_HEIGHT:
        case MAX_WIDTH:
        case MAX_HEIGHT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsNumber()) {
                break;
            }

            *result = value.As<v8::Number>()->Value();
            return true;
        }
        default: {
            break;
        }
    }
    return false;
}

extern "C" int64_t javascript_style_get_string_length(void* runtime_opaque, void* style_object, JavascriptStyleField field) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BORDER_STYLE:
        case TEXT_WRAPPING:
        case CURSOR:
        case OVERFLOW:
        case X_JUSTIFICATION:
        case Y_JUSTIFICATION:
        case DIRECTION:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsString()) {
                break;
            }

            return (int64_t) value.As<v8::String>()->Utf8LengthV2(runtime->isolate);
        }
        default: {
            break;
        }
    }
    return 0;
}

extern "C" bool javascript_style_copy_string(void* runtime_opaque, void* style_object, JavascriptStyleField field, uint8_t* result, int64_t result_count) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BORDER_STYLE:
        case TEXT_WRAPPING:
        case CURSOR:
        case OVERFLOW:
        case X_JUSTIFICATION:
        case Y_JUSTIFICATION:
        case DIRECTION:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsString()) {
                break;
            }

            auto string = value.As<v8::String>();
            auto length = (int64_t) string->Utf8LengthV2(runtime->isolate);
            if (result_count < length) {
                break;
            }

            string->WriteUtf8V2(runtime->isolate, (char*) result, (size_t) length);
            return true;
        }
        default: {
            break;
        }
    }
    return false;
}

extern "C" int64_t javascript_style_get_array_count(void* runtime_opaque, void* style_object, JavascriptStyleField field) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BACKGROUND:
        case COLOR:
        case BORDER_COLOR:
        case BORDER_WIDTH:
        case SHADOW:
        case PLACEMENT:
        case WIDTH:
        case HEIGHT:
        case TRANSLATE:
        case PADDING:
        case MARGIN:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsArray()) {
                break;
            }

            return (int64_t) value.As<v8::Array>()->Length();
        }
        default: {
            break;
        }
    }
    return 0;
}

extern "C" bool javascript_style_get_array_number(void* runtime_opaque, void* style_object, JavascriptStyleField field, int64_t index, double* result) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BACKGROUND:
        case COLOR:
        case BORDER_COLOR:
        case BORDER_WIDTH:
        case SHADOW:
        case PLACEMENT:
        case WIDTH:
        case HEIGHT:
        case TRANSLATE:
        case PADDING:
        case MARGIN:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsArray()) {
                break;
            }

            auto array = value.As<v8::Array>();
            if (index < 0 || index >= (int64_t) array->Length()) {
                break;
            }

            auto maybe_element = array->Get(context, (uint32_t) index);
            v8::Local<v8::Value> element;
            if (!maybe_element.ToLocal(&element) || !element->IsNumber()) {
                break;
            }

            *result = element.As<v8::Number>()->Value();
            return true;
        }
        default: {
            break;
        }
    }
    return false;
}

extern "C" int64_t javascript_style_get_array_string_length(void* runtime_opaque, void* style_object, JavascriptStyleField field, int64_t index) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BACKGROUND:
        case PLACEMENT:
        case WIDTH:
        case HEIGHT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsArray()) {
                break;
            }

            auto array = value.As<v8::Array>();
            if (index < 0 || index >= (int64_t) array->Length()) {
                break;
            }

            auto maybe_element = array->Get(context, (uint32_t) index);
            v8::Local<v8::Value> element;
            if (!maybe_element.ToLocal(&element) || !element->IsString()) {
                break;
            }

            return (int64_t) element.As<v8::String>()->Utf8LengthV2(runtime->isolate);
        }
        default: {
            break;
        }
    }
    return 0;
}

extern "C" bool javascript_style_copy_array_string(void* runtime_opaque, void* style_object, JavascriptStyleField field, int64_t index, uint8_t* result, int64_t result_count) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case BACKGROUND:
        case PLACEMENT:
        case WIDTH:
        case HEIGHT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsArray()) {
                break;
            }

            auto array = value.As<v8::Array>();
            if (index < 0 || index >= (int64_t) array->Length()) {
                break;
            }

            auto maybe_element = array->Get(context, (uint32_t) index);
            v8::Local<v8::Value> element;
            if (!maybe_element.ToLocal(&element) || !element->IsString()) {
                break;
            }

            auto string = element.As<v8::String>();
            auto length = (int64_t) string->Utf8LengthV2(runtime->isolate);
            if (result_count < length) {
                break;
            }

            string->WriteUtf8V2(runtime->isolate, (char*) result, (size_t) length);
            return true;
        }
        default: {
            break;
        }
    }
    return false;
}

extern "C" void* javascript_style_get_external(void* runtime_opaque, void* style_object, JavascriptStyleField field) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    auto object = *static_cast<v8::Local<v8::Object>*>(style_object);
    auto context = runtime->context->Get(runtime->isolate);
    switch (field) {
        case FONT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(runtime->isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsExternal()) {
                break;
            }

            return value.As<v8::External>()->Value();
        }
        default: {
            break;
        }
    }
    return nullptr;
}
