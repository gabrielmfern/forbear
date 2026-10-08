#include "node.h"
#include "v8-container.h"
#include "v8-exception.h"
#include "v8-function-callback.h"
#include "v8-isolate.h"
#include "v8-object.h"
#include "v8-platform.h"
#include "v8-primitive.h"
#include "v8-locker.h"
#include <cmath>
#include <cstdint>
#include <numbers>

extern "C" void forbear_open(void* adapter, void* js_style_object, char* manual_key_data, int64_t manual_key_count);
extern "C" void forbear_close(void* adapter);
extern "C" void forbear_text(void* adapter, void* js_style_object, char* content_data, int64_t content_count, char* manual_key_data, int64_t manual_key_count);

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
    void* adapter;

    std::unique_ptr<node::CommonEnvironmentSetup> setup;

    v8::Global<v8::Function> render;

    v8::Global<v8::String> property_names[DIRECTION + 1];
    v8::Global<v8::String> fixed_string;
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
    if (info.Length() >= 1 && info[0]->IsNumber()) {
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

void fit(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    auto sizing = v8::Array::New(isolate, 1);
    sizing->Set(context, 0, runtime->fit_string.Get(isolate)).Check();
    return_value.Set(sizing);
}

void grow(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto sizing = v8::Array::New(isolate, 2);
        sizing->Set(context, 0, runtime->grow_string.Get(isolate)).Check();
        sizing->Set(context, 1, number).Check();
        return_value.Set(sizing);
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "grow expects one number")
        ));
    }
}

void flow(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    auto placement = v8::Array::New(isolate, 1);
    placement->Set(context, 0, runtime->flow_string.Get(isolate)).Check();
    return_value.Set(placement);
}

void relative(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    if (info.Length() >= 1 && info[0]->IsArray()) {
        auto vector2 = info[0].As<v8::Array>();
        auto placement = v8::Array::New(isolate, 3);
        placement->Set(context, 0, runtime->relative_string.Get(isolate)).Check();
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
                v8::String::NewFromUtf8Literal(isolate, "relative expects a Vector2, an array of two numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "relative expects a Vector2")
        ));
    }
}

void rgb(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 3 &&
        info[0]->IsNumber() &&
        info[1]->IsNumber() &&
        info[2]->IsNumber()) {
        auto vector4 = v8::Array::New(isolate, 4);
        vector4->Set(context, 0, v8::Number::New(isolate, info[0].As<v8::Number>()->Value() / 255.0)).Check();
        vector4->Set(context, 1, v8::Number::New(isolate, info[1].As<v8::Number>()->Value() / 255.0)).Check();
        vector4->Set(context, 2, v8::Number::New(isolate, info[2].As<v8::Number>()->Value() / 255.0)).Check();
        vector4->Set(context, 3, v8::Number::New(isolate, 1.0)).Check();
        return_value.Set(vector4);
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "rgb expects three numbers")
        ));
    }
}

void rgba(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 4 &&
        info[0]->IsNumber() &&
        info[1]->IsNumber() &&
        info[2]->IsNumber() &&
        info[3]->IsNumber()) {
        auto vector4 = v8::Array::New(isolate, 4);
        vector4->Set(context, 0, v8::Number::New(isolate, info[0].As<v8::Number>()->Value() / 255.0)).Check();
        vector4->Set(context, 1, v8::Number::New(isolate, info[1].As<v8::Number>()->Value() / 255.0)).Check();
        vector4->Set(context, 2, v8::Number::New(isolate, info[2].As<v8::Number>()->Value() / 255.0)).Check();
        vector4->Set(context, 3, info[3].As<v8::Number>()).Check();
        return_value.Set(vector4);
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "rgba expects four numbers")
        ));
    }
}

void color(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    if (info.Length() >= 1 && info[0]->IsArray()) {
        auto vector4 = info[0].As<v8::Array>();
        v8::Local<v8::Value> r;
        v8::Local<v8::Value> g;
        v8::Local<v8::Value> b;
        v8::Local<v8::Value> a;
        if (vector4->Get(context, 0).ToLocal(&r) &&
            vector4->Get(context, 1).ToLocal(&g) &&
            vector4->Get(context, 2).ToLocal(&b) &&
            vector4->Get(context, 3).ToLocal(&a) &&
            r->IsNumber() &&
            g->IsNumber() &&
            b->IsNumber() &&
            a->IsNumber()) {
            auto background = v8::Array::New(isolate, 5);
            background->Set(context, 0, runtime->color_string.Get(isolate)).Check();
            background->Set(context, 1, r).Check();
            background->Set(context, 2, g).Check();
            background->Set(context, 3, b).Check();
            background->Set(context, 4, a).Check();
            return_value.Set(background);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "color expects a Vector4, an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "color expects a Vector4")
        ));
    }
}

void gradient(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsArray()) {
        auto direction = info[0].As<v8::Array>();
        auto stops = info[1].As<v8::Array>();
        v8::Local<v8::Value> x;
        v8::Local<v8::Value> y;
        if (direction->Get(context, 0).ToLocal(&x) &&
            direction->Get(context, 1).ToLocal(&y) &&
            x->IsNumber() &&
            y->IsNumber()) {
            auto stop_count = stops->Length();
            auto background = v8::Array::New(isolate, 3 + stop_count * 5);
            background->Set(context, 0, runtime->gradient_string.Get(isolate)).Check();
            background->Set(context, 1, x).Check();
            background->Set(context, 2, y).Check();
            for (uint32_t i = 0; i < stop_count; ++i) {
                v8::Local<v8::Value> stop_value;
                if (!stops->Get(context, i).ToLocal(&stop_value) || !stop_value->IsArray()) {
                    isolate->ThrowException(v8::Exception::TypeError(
                        v8::String::NewFromUtf8Literal(isolate, "gradient expects each stop to be an array of five numbers")
                    ));
                    return;
                }
                auto stop = stop_value.As<v8::Array>();
                v8::Local<v8::Value> r;
                v8::Local<v8::Value> g;
                v8::Local<v8::Value> b;
                v8::Local<v8::Value> a;
                v8::Local<v8::Value> position;
                if (stop->Get(context, 0).ToLocal(&r) &&
                    stop->Get(context, 1).ToLocal(&g) &&
                    stop->Get(context, 2).ToLocal(&b) &&
                    stop->Get(context, 3).ToLocal(&a) &&
                    stop->Get(context, 4).ToLocal(&position) &&
                    r->IsNumber() &&
                    g->IsNumber() &&
                    b->IsNumber() &&
                    a->IsNumber() &&
                    position->IsNumber()) {
                    auto index = 3 + i * 5;
                    background->Set(context, index, r).Check();
                    background->Set(context, index + 1, g).Check();
                    background->Set(context, index + 2, b).Check();
                    background->Set(context, index + 3, a).Check();
                    background->Set(context, index + 4, position).Check();
                } else {
                    isolate->ThrowException(v8::Exception::TypeError(
                        v8::String::NewFromUtf8Literal(isolate, "gradient expects each stop to be an array of five numbers")
                    ));
                    return;
                }
            }
            return_value.Set(background);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "gradient expects a Vector2 for the direction")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "gradient expects a Vector2 and an array of GradientStops")
        ));
    }
}

void all(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, number).Check();
        sides->Set(context, 1, number).Check();
        sides->Set(context, 2, number).Check();
        sides->Set(context, 3, number).Check();
        return_value.Set(sides);
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "all expects one number")
        ));
    }
}

void in_line(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto zero = v8::Number::New(isolate, 0.0);
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, number).Check();
        sides->Set(context, 1, number).Check();
        sides->Set(context, 2, zero).Check();
        sides->Set(context, 3, zero).Check();
        return_value.Set(sides);
    } else if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsNumber()) {
        auto existing = info[0].As<v8::Array>();
        auto number = info[1].As<v8::Number>();
        v8::Local<v8::Value> top;
        v8::Local<v8::Value> bottom;
        if (existing->Get(context, 2).ToLocal(&top) &&
            existing->Get(context, 3).ToLocal(&bottom) &&
            top->IsNumber() &&
            bottom->IsNumber()) {
            auto sides = v8::Array::New(isolate, 4);
            sides->Set(context, 0, number).Check();
            sides->Set(context, 1, number).Check();
            sides->Set(context, 2, top).Check();
            sides->Set(context, 3, bottom).Check();
            return_value.Set(sides);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "inLine with Sides expects an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "inLine expects a number, or a Sides array and a number")
        ));
    }
}

void block(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto zero = v8::Number::New(isolate, 0.0);
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, zero).Check();
        sides->Set(context, 1, zero).Check();
        sides->Set(context, 2, number).Check();
        sides->Set(context, 3, number).Check();
        return_value.Set(sides);
    } else if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsNumber()) {
        auto existing = info[0].As<v8::Array>();
        auto number = info[1].As<v8::Number>();
        v8::Local<v8::Value> left;
        v8::Local<v8::Value> right;
        if (existing->Get(context, 0).ToLocal(&left) &&
            existing->Get(context, 1).ToLocal(&right) &&
            left->IsNumber() &&
            right->IsNumber()) {
            auto sides = v8::Array::New(isolate, 4);
            sides->Set(context, 0, left).Check();
            sides->Set(context, 1, right).Check();
            sides->Set(context, 2, number).Check();
            sides->Set(context, 3, number).Check();
            return_value.Set(sides);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "block with Sides expects an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "block expects a number, or a Sides array and a number")
        ));
    }
}

void left(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto zero = v8::Number::New(isolate, 0.0);
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, number).Check();
        sides->Set(context, 1, zero).Check();
        sides->Set(context, 2, zero).Check();
        sides->Set(context, 3, zero).Check();
        return_value.Set(sides);
    } else if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsNumber()) {
        auto existing = info[0].As<v8::Array>();
        auto number = info[1].As<v8::Number>();
        v8::Local<v8::Value> right;
        v8::Local<v8::Value> top;
        v8::Local<v8::Value> bottom;
        if (existing->Get(context, 1).ToLocal(&right) &&
            existing->Get(context, 2).ToLocal(&top) &&
            existing->Get(context, 3).ToLocal(&bottom) &&
            right->IsNumber() &&
            top->IsNumber() &&
            bottom->IsNumber()) {
            auto sides = v8::Array::New(isolate, 4);
            sides->Set(context, 0, number).Check();
            sides->Set(context, 1, right).Check();
            sides->Set(context, 2, top).Check();
            sides->Set(context, 3, bottom).Check();
            return_value.Set(sides);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "left with Sides expects an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "left expects a number, or a Sides array and a number")
        ));
    }
}

void right(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto zero = v8::Number::New(isolate, 0.0);
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, zero).Check();
        sides->Set(context, 1, number).Check();
        sides->Set(context, 2, zero).Check();
        sides->Set(context, 3, zero).Check();
        return_value.Set(sides);
    } else if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsNumber()) {
        auto existing = info[0].As<v8::Array>();
        auto number = info[1].As<v8::Number>();
        v8::Local<v8::Value> left;
        v8::Local<v8::Value> top;
        v8::Local<v8::Value> bottom;
        if (existing->Get(context, 0).ToLocal(&left) &&
            existing->Get(context, 2).ToLocal(&top) &&
            existing->Get(context, 3).ToLocal(&bottom) &&
            left->IsNumber() &&
            top->IsNumber() &&
            bottom->IsNumber()) {
            auto sides = v8::Array::New(isolate, 4);
            sides->Set(context, 0, left).Check();
            sides->Set(context, 1, number).Check();
            sides->Set(context, 2, top).Check();
            sides->Set(context, 3, bottom).Check();
            return_value.Set(sides);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "right with Sides expects an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "right expects a number, or a Sides array and a number")
        ));
    }
}

void top(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto zero = v8::Number::New(isolate, 0.0);
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, zero).Check();
        sides->Set(context, 1, zero).Check();
        sides->Set(context, 2, number).Check();
        sides->Set(context, 3, zero).Check();
        return_value.Set(sides);
    } else if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsNumber()) {
        auto existing = info[0].As<v8::Array>();
        auto number = info[1].As<v8::Number>();
        v8::Local<v8::Value> left;
        v8::Local<v8::Value> right;
        v8::Local<v8::Value> bottom;
        if (existing->Get(context, 0).ToLocal(&left) &&
            existing->Get(context, 1).ToLocal(&right) &&
            existing->Get(context, 3).ToLocal(&bottom) &&
            left->IsNumber() &&
            right->IsNumber() &&
            bottom->IsNumber()) {
            auto sides = v8::Array::New(isolate, 4);
            sides->Set(context, 0, left).Check();
            sides->Set(context, 1, right).Check();
            sides->Set(context, 2, number).Check();
            sides->Set(context, 3, bottom).Check();
            return_value.Set(sides);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "top with Sides expects an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "top expects a number, or a Sides array and a number")
        ));
    }
}

void bottom(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto number = info[0].As<v8::Number>();
        auto zero = v8::Number::New(isolate, 0.0);
        auto sides = v8::Array::New(isolate, 4);
        sides->Set(context, 0, zero).Check();
        sides->Set(context, 1, zero).Check();
        sides->Set(context, 2, zero).Check();
        sides->Set(context, 3, number).Check();
        return_value.Set(sides);
    } else if (info.Length() >= 2 && info[0]->IsArray() && info[1]->IsNumber()) {
        auto existing = info[0].As<v8::Array>();
        auto number = info[1].As<v8::Number>();
        v8::Local<v8::Value> left;
        v8::Local<v8::Value> right;
        v8::Local<v8::Value> top;
        if (existing->Get(context, 0).ToLocal(&left) &&
            existing->Get(context, 1).ToLocal(&right) &&
            existing->Get(context, 2).ToLocal(&top) &&
            left->IsNumber() &&
            right->IsNumber() &&
            top->IsNumber()) {
            auto sides = v8::Array::New(isolate, 4);
            sides->Set(context, 0, left).Check();
            sides->Set(context, 1, right).Check();
            sides->Set(context, 2, top).Check();
            sides->Set(context, 3, number).Check();
            return_value.Set(sides);
        } else {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "bottom with Sides expects an array of four numbers")
            ));
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "bottom expects a number, or a Sides array and a number")
        ));
    }
}

void angle(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    if (info.Length() >= 1 && info[0]->IsNumber()) {
        auto radians = info[0].As<v8::Number>()->Value() * std::numbers::pi / 180.0;
        auto vector2 = v8::Array::New(isolate, 2);
        vector2->Set(context, 0, v8::Number::New(isolate, std::sin(radians))).Check();
        vector2->Set(context, 1, v8::Number::New(isolate, -std::cos(radians))).Check();
        return_value.Set(vector2);
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "angle expects one number")
        ));
    }
}

void to_top(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, 0.0)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, -1.0)).Check();
    return_value.Set(vector2);
}

void to_bottom(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, 0.0)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, 1.0)).Check();
    return_value.Set(vector2);
}

void to_left(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, -1.0)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, 0.0)).Check();
    return_value.Set(vector2);
}

void to_right(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, 1.0)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, 0.0)).Check();
    return_value.Set(vector2);
}

void to_top_left(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto h = std::sqrt(0.5);
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, -h)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, -h)).Check();
    return_value.Set(vector2);
}

void to_top_right(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto h = std::sqrt(0.5);
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, h)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, -h)).Check();
    return_value.Set(vector2);
}

void to_bottom_left(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto h = std::sqrt(0.5);
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, -h)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, h)).Check();
    return_value.Set(vector2);
}

void to_bottom_right(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto context = isolate->GetCurrentContext();
    auto return_value = info.GetReturnValue();
    auto h = std::sqrt(0.5);
    auto vector2 = v8::Array::New(isolate, 2);
    vector2->Set(context, 0, v8::Number::New(isolate, h)).Check();
    vector2->Set(context, 1, v8::Number::New(isolate, h)).Check();
    return_value.Set(vector2);
}

void js_open(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    v8::Local<v8::Object> style;
    v8::Local<v8::Value> manual_key = v8::String::Empty(isolate);
    if (info.Length() >= 1 && info[0]->IsObject() && !info[0]->IsArray()) {
        style = info[0].As<v8::Object>();
        if (info.Length() >= 2 && info[1]->IsString()) {
            manual_key = info[1];
        } else if (info.Length() >= 2 && !info[1]->IsNullOrUndefined()) {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "open expects a string for the manual key")
            ));
            return;
        }
    } else if (info.Length() >= 1 && info[0]->IsString()) {
        style = v8::Object::New(isolate);
        manual_key = info[0];
    } else if (info.Length() == 0 || info[0]->IsNullOrUndefined()) {
        style = v8::Object::New(isolate);
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "open expects a Style object, a string key, or no arguments")
        ));
        return;
    }
    v8::String::Utf8Value key(isolate, manual_key);
    forbear_open(runtime->adapter, &style, *key, key.length());
}

void js_close(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    forbear_close(runtime->adapter);
}

void js_text(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto runtime = static_cast<JavascriptRuntime*>(
        v8::External::Cast(*info.Data())->Value()
    );
    v8::Local<v8::Object> style;
    v8::Local<v8::Value> content;
    v8::Local<v8::Value> manual_key = v8::String::Empty(isolate);
    if (info.Length() >= 2 && info[0]->IsObject() && !info[0]->IsArray() && info[1]->IsString()) {
        style = info[0].As<v8::Object>();
        content = info[1];
        if (info.Length() >= 3 && info[2]->IsString()) {
            manual_key = info[2];
        } else if (info.Length() >= 3 && !info[2]->IsNullOrUndefined()) {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "text expects a string for the manual key")
            ));
            return;
        }
    } else if (info.Length() >= 1 && info[0]->IsString()) {
        style = v8::Object::New(isolate);
        content = info[0];
        if (info.Length() >= 2 && info[1]->IsString()) {
            manual_key = info[1];
        } else if (info.Length() >= 2 && !info[1]->IsNullOrUndefined()) {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "text expects a string for the manual key")
            ));
            return;
        }
    } else {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "text expects a content string, or a Style object and a content string")
        ));
        return;
    }
    v8::String::Utf8Value content_utf8(isolate, content);
    v8::String::Utf8Value key(isolate, manual_key);
    forbear_text(runtime->adapter, &style, *content_utf8, content_utf8.length(), *key, key.length());
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

extern "C" void* javascript_init(
    void* adapter,
    char* source_data, 
    int64_t source_count, 
    char* source_name_data, 
    int64_t source_name_count
) {
    auto runtime = new JavascriptRuntime;
    runtime->adapter = adapter;

    std::vector<std::string> args = { "forbear" };
    auto init = node::InitializeOncePerProcess(args, {});
    if (!init->early_return()) {
        // TODO: should we have this thread pool be configurable?
        auto platform = init->platform();
        std::vector<std::string> errors;
        runtime->setup = node::CommonEnvironmentSetup::Create(platform, &errors, init->args(), init->exec_args());
        if (runtime->setup != nullptr) {
            
            auto isolate = runtime->setup->isolate();
            v8::Locker locker(isolate);
            v8::Isolate::Scope isolate_scope(isolate);
            v8::HandleScope handle_scope(isolate);
            v8::Context::Scope context_scope(runtime->setup->context());
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
            runtime->grow_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "grow"));
            runtime->flow_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "flow"));
            runtime->relative_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "relative"));
            runtime->color_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "color"));
            runtime->gradient_string.Reset(isolate, v8::String::NewFromUtf8Literal(isolate, "gradient"));

            define_global_function(runtime, runtime->fixed_string.Get(isolate), fixed);
            define_global_function(runtime, runtime->fit_string.Get(isolate), fit);
            define_global_function(runtime, runtime->grow_string.Get(isolate), grow);
            define_global_function(runtime, runtime->flow_string.Get(isolate), flow);
            define_global_function(runtime, runtime->relative_string.Get(isolate), relative);
            define_global_function(runtime, runtime->color_string.Get(isolate), color);
            define_global_function(runtime, runtime->gradient_string.Get(isolate), gradient);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "rgb"), rgb);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "rgba"), rgba);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "all"), all);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "inLine"), in_line);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "inline"), in_line);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "block"), block);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "left"), left);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "right"), right);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "top"), top);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "bottom"), bottom);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "angle"), angle);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toTop"), to_top);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toBottom"), to_bottom);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toLeft"), to_left);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toRight"), to_right);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toTopLeft"), to_top_left);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toTopRight"), to_top_right);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toBottomLeft"), to_bottom_left);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "toBottomRight"), to_bottom_right);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "open"), js_open);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "close"), js_close);
            define_global_function(runtime, v8::String::NewFromUtf8Literal(isolate, "text"), js_text);
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
    } else {
        // TODO: print init->errors()
    }

    return nullptr;
}

extern "C" bool javascript_render(void* runtime_opaque) {
    auto runtime = static_cast<JavascriptRuntime*>(runtime_opaque);
    if (!runtime->render.IsEmpty()) {
        auto isolate = runtime->setup->isolate();
        v8::Locker locker(isolate);
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        v8::Context::Scope context_scope(runtime->setup->context());
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
