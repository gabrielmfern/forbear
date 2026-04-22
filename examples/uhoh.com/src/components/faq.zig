const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

const faqs = [_]struct {
    question: []const u8,
    answer: []const u8,
}{
    .{
        .question = "So is this an MSP?",
        .answer = "Yeah. Pretty much. Broad strokes purposes... yes. But without the crap they put you through. There's no egos here and confusing jargon that makes you feel bad about yourself. Book a meeting and we'll tell you more about what makes us different.",
    },
    .{
        .question = "What if I have more than 50 people?",
        .answer = "We can talk about that. We're sure we can work something out.",
    },
    .{
        .question = "Is there a trial?",
        .answer = "Yeah, there's a 30 day trial. Don't hold back. Give us your hardest problems.",
    },
    .{
        .question = "Do you manage cybersecurity?",
        .answer = "Yes.",
    },
};

pub fn Faq() void {
    Section(.{
        .yJustification = .start,
    })({
        forbear.element(.{ .direction = .vertical })({
            forbear.element(.{
                .fontWeight = 700,
                .fontSize = 21.0,
                .margin = forbear.Margin.block(0.0).withBottom(13.5),
            })({
                forbear.text("FAQ");
            });
            inline for (faqs) |faq| {
                forbear.element(.{
                    .borderRadius = 9.0,
                    .borderColor = colors.black,
                    .borderWidth = .all(0.75),
                    .padding = .all(12.0),
                    .margin = forbear.Margin.block(0.0).withBottom(9.0),
                })({
                    forbear.element(.{
                        .fontWeight = 600,
                        .fontSize = 12.0,
                        .margin = forbear.Margin.block(0.0).withBottom(6.0),
                    })({
                        forbear.text(faq.question);
                    });
                    forbear.element(.{
                        .fontSize = 10.5,
                    })({
                        forbear.text(faq.answer);
                    });
                });
            }
        });
    });
}
