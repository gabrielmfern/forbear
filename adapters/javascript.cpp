#include "node.h"
#include "v8-container.h"
#include "v8-exception.h"
#include "v8-function-callback.h"
#include "v8-isolate.h"
#include "v8-platform.h"
#include <cstdint>

extern "C" void forbear_open(void* adapter, void* js_style_object, char* manual_key_data, int64_t manual_key_count);
extern "C" void forbear_close(void* adapter);
extern "C" void forbear_text_push(void* adapter, void* js_style_object, char* content_data, int64_t content_count, char* manual_key_data, int64_t manual_key_count);

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
    std::unique_ptr<node::MultiIsolatePlatform> platform;
    std::unique_ptr<node::CommonEnvironmentSetup> setup;

    v8::Global<v8::Function> render;

    v8::Global<v8::String> property_names[DIRECTION + 1];
    v8::Global<v8::String> fixed_string;
    v8::Global<v8::String> ratio_string;
    v8::Global<v8::String> grow_string;
    v8::Global<v8::String> fit_string;
    v8::Global<v8::String> flow_string;
    v8::Global<v8::String> relative_string;
    v8::Global<v8::String> color_string;
    v8::Global<v8::String> gradient_string;
};

void fixed(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    if (info.Length() >= 1 && info[0]->IsArray()) {
        auto number = info[0].As<v8::Number>();
        auto sizing = v8::Array::New(isolate, 2);
        sizing->Set(context, 0, runtime->fixed_string.Get(isolate)).Check();
        sizing->Set(context, 1, number).Check();
        return_value.Set(sizing);
    } else if (info.Length() >= 1 && info[0]->IsArray()) {
        auto vector2 = info[0].As<v8::Array>();
        auto placement = v8::Array::New(isolate, 3);
        placement->Set(context, 0, runtime->fixed_string.Get(isolate)).Check();
        v8::Local<v8::Value> x;
        v8::Local<v8::Value> y;
        if (vector2->Get(context, 0).ToLocal(&x) && 
            vector2->Get(context, 1).ToLocal(&y) && 
            x->IsNumber()                        && 
            y->IsNumber()) {
            placement->Set(context, 1, x).Check();
            placement->Set(context, 2, y).Check();
            return_value.Set(placement);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "fixed with a vector, expects the vector to be an array of two numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "fixed expects either one number, or a Vector2")
        ));
    }
}

void set_render_function(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    if (info.Length() >= 1 && info[0]->IsFunction()) {
        runtime->render.Reset(isolate, info[0].As<v8::Function>());
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "setRender expects a function as a parameter")
        ));
    }
}

void define_global_function(JavascriptRuntime* runtime, v8::Local<v8::String> name, v8::FunctionCallback function) {
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
    auto env = runtime->setup->env();

    auto function_template = v8::FunctionTemplate::New(
        isolate,
        function,
        v8::External::New(isolate, runtime)
    )->GetFunction(context).ToLocalChecked();
    context->Global()->Set(context, name, function_template).Check();
}

extern "C" void* javascript_init(char* source_data, int64_t source_count, char* source_name_data, int64_t source_name_count) {
    auto runtime = new JavascriptRuntime;

    // TODO: should we have this thread pool be configurable?
    runtime->platform = node::MultiIsolatePlatform::Create(1);
    auto platform = runtime->platform.get();
    std::vector<std::string> errors;
    // TODO: "forbear" here is the process name. should we have this be configurable?
    std::vector<std::string> args = { "forbear" };
    // TODO: should we have these exec_args configurable?
    std::vector<std::string> exec_args;
    runtime->setup = node::CommonEnvironmentSetup::Create(platform, &errors, args, exec_args);
    if (runtime->setup != nullptr) {
        auto isolate = runtime->setup->isolate();
        auto context = runtime->setup->context();
        auto env = runtime->setup->env();

        for (uint8_t field = 0; field <= DIRECTION; ++field) {
            runtime->property_names[field].Reset(
                isolate,
                v8::String::NewFromUtf8(
                    isolate,
                    style_field_names[field],
                    v8::NewStringType::kInternalized
                ).ToLocalChecked()
            );
        }

        runtime->fixed_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "fixed"));
        runtime->fit_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "fit"));
        runtime->ratio_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "ratio"));
        runtime->grow_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "grow"));
        runtime->relative_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "relative"));
        runtime->color_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "color"));
        runtime->gradient_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "gradient"));

        define_global_function(runtime, runtime->fixed_string.Get(isolate), fixed);
        define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "setRenderFunction"), set_render_function);

        node::ModuleData entry;
        entry.set_source(std::string_view(source_data, source_count));
        entry.set_format(node::ModuleFormat::kModule);
        entry.set_resource_name(std::string_view(source_name_data, source_name_count));
        auto loaded = node::LoadEnvironment(
            runtime->setup->env(),
            &entry
        );
        if (!loaded.IsEmpty()) {
            return (void*) runtime;
        }
    }

    return nullptr;
}

extern "C" bool javascript_render(void* runtime_opaque) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    if (!runtime->render.IsEmpty()) {
        auto isolate = runtime->setup->isolate();
        auto context = runtime->setup->context();
        // v8::TryCatch try_catch(isolate);

        v8::Local<v8::Value> result;
        if (runtime->render.Get(isolate)->Call(context, v8::Undefined(isolate), 0, nullptr).ToLocal(&result)) {
            return true;
        } else {
            // TODO: handle the exception here somehow
            // auto exception = try_catch.Exception();
        }
    }

    return false;
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
    
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
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
                runtime->property_names[field].Get(isolate)
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
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
                runtime->property_names[field].Get(isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsString()) {
                break;
            }

            return (int64_t) value.As<v8::String>()->Utf8LengthV2(isolate);
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
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
                runtime->property_names[field].Get(isolate)
            );
            v8::Local<v8::Value> value;
            if (!maybe_value.ToLocal(&value) || !value->IsString()) {
                break;
            }

            auto string = value.As<v8::String>();
            auto length = (int64_t) string->Utf8LengthV2(isolate);
            if (result_count < length) {
                break;
            }

            string->WriteUtf8V2(isolate, (char*) result, (size_t) length);
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
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
                runtime->property_names[field].Get(isolate)
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
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
                runtime->property_names[field].Get(isolate)
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
    switch (field) {
        case BACKGROUND:
        case PLACEMENT:
        case WIDTH:
        case HEIGHT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(isolate)
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

            return (int64_t) element.As<v8::String>()->Utf8LengthV2(isolate);
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
    switch (field) {
        case BACKGROUND:
        case PLACEMENT:
        case WIDTH:
        case HEIGHT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(isolate)
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
            auto length = (int64_t) string->Utf8LengthV2(isolate);
            if (result_count < length) {
                break;
            }

            string->WriteUtf8V2(isolate, (char*) result, (size_t) length);
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
    auto isolate = runtime->setup->isolate();
    auto context = runtime->setup->context();
    switch (field) {
        case FONT:
        {
            auto maybe_value = object->Get(
                context,
                runtime->property_names[field].Get(isolate)
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
