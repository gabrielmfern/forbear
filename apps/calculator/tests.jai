#import "Basic";
Main :: #import,file "./main.jai";
operator == :: Main.operator ==;

BUILD_FLAGS :: "+forbear";

test :: (name: string, body: Code) #expand {
    print("TEST %\n", name);
    #insert body;
    print("PASS\n");
}

main :: () {
    test("parse_expression", #code {
        tokens: [..]Main.Token;
        expression := "5 + 10 - 12 / 4 * 19";
        result     := Main.parse_expression(expression, *tokens);
        assert(result == .SUCCESS);
        assert(tokens[0] == Main.Token.{kind=.NUMBER,number=5});
        assert(tokens[1] == Main.ADD);
        assert(tokens[2] == Main.Token.{kind=.NUMBER,number=10});
        assert(tokens[3] == Main.SUBTRACT);
        assert(tokens[4] == Main.Token.{kind=.NUMBER,number=12});
        assert(tokens[5] == Main.DIVIDE);
        assert(tokens[6] == Main.Token.{kind=.NUMBER,number=4});
        assert(tokens[7] == Main.MULTIPLY);
        assert(tokens[8] == Main.Token.{kind=.NUMBER,number=19});
    });

    test("reverse_number_sign", #code {
        text: [..]u8;
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "");

        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "-123");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "-");
        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "123");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "-");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "-");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        array_add(*text, #char "-");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "123-");

        array_reset_keeping_memory(*text);
        array_add(*text, #char "1");
        array_add(*text, #char "2");
        array_add(*text, #char "3");
        array_add(*text, #char " ");
        array_add(*text, #char "-");
        Main.reverse_number_sign(*text);
        assert(to_string(text.data, text.count) == "123 -");
    });
}
