const forbear = @import("forbear");
const Testimonial = @import("testimonial.zig").Testimonial;

pub fn TestimonialsSection() void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .yJustification = .start,
        .direction = .vertical,
        .padding = forbear.Padding.top(22.5).withBottom(30.0),
    })({
        forbear.element(.{
            .fontWeight = 700,
            .fontSize = 30,
            .margin = forbear.Margin.top(15.0).withBottom(18.75),
        })({
            forbear.text("Don't take our word for it.");
        });
        forbear.element(.{
            .width = .{ .grow = 1.0 },
            .direction = .vertical,
        })({
            forbear.element(.{
                .width = .{ .grow = 1.0 },
            })({
                Testimonial("uhoh-testimonial-1", .{ .margin = .bottom(20.0) })({
                    forbear.text("I'll be honest, we didn't know we needed help with the IT/Tech side of our business. After bringing on uhoh, I realized that I was very wrong. In the first month we built out systems and processes that will give us the capacity to scale well past where we were targeting for this year. Bonus is any time we have a problem and hit a wall, they just fix it. It really is like having a full IT team on standby. 10/10 recommend this.");

                    forbear.element(.{
                        .margin = .top(32.0),
                        .direction = .vertical,
                    })({
                        forbear.text("Clifton Sellers, Founder/CEO");
                        forbear.text("Legacy Builders");
                    });
                });

                Testimonial("uhoh-testimonial-2", .{ .margin = forbear.Margin.inLine(20.0).withBottom(20.0) })({
                    forbear.text("uhoh is reliable and easy to work with. They solve complex problems quickly and bring forward smart, modern solutions that actually move the business forward. What sets them apart is how deeply they think about the company's vision, not just fixing tech issues but using technology to support growth, efficiency, and long-term impact.");

                    forbear.element(.{
                        .margin = .top(32.0),
                        .direction = .vertical,
                    })({
                        forbear.text("Na'eem Adam, Founder/CEO");
                        forbear.text("Parkour, Le Burger Week");
                    });
                });

                Testimonial("uhoh-testimonial-moses", .{ .margin = .bottom(20.0) })({
                    forbear.text("I had an incredible experience with uhoh. They were fast, professional, and knowledgeable. I really appreciated their transparent flat-fee pricing, which made the whole process stress-free and affordable. They handled everything with ease and went above and beyond to make sure I was satisfied. Highly recommend to anyone looking for reliable systems support!");

                    forbear.element(.{
                        .margin = .top(32.0),
                        .direction = .vertical,
                    })({
                        forbear.text("Moses Lam, Owner");
                        forbear.text("Artisanal Mortgages");
                    });
                });
            });

            forbear.element(.{
                .width = .{ .grow = 1.0 },
            })({
                Testimonial("uhoh-testimonial-alex", .{})({
                    forbear.text("One of the best decisions I've made as a founder. So much time saved to focus on everything else. I didn't even realize how much time I was losing previously. Highly recommend.");

                    forbear.element(.{
                        .margin = .top(32.0),
                        .direction = .vertical,
                    })({
                        forbear.text("Alex Stewart, Founder/CEO");
                        forbear.text("Teamtown");
                    });
                });

                Testimonial("uhoh-testimonial-stephanie", .{ .margin = .inLine(20.0) })({
                    forbear.text("uhoh has been the solution I didn't know I needed. Deep and Erica are empathetic and care about the things I need in my business to be successful. They are working behind the scenes to help me scale without adding people. Thank you for your support!");

                    forbear.element(.{
                        .margin = .top(32.0),
                        .direction = .vertical,
                    })({
                        forbear.text("Stephanie O'Brien, President");
                        forbear.text("Carmella");
                    });
                });

                Testimonial("uhoh-testimonial-enoch", .{})({
                    forbear.text("We've been using uhoh since they started and it's been a pleasure. Great attention to detail, super proactive and always delivering value.");

                    forbear.element(.{
                        .margin = .top(32.0),
                        .direction = .vertical,
                    })({
                        forbear.text("Enoch Taralson, Director of Revenue Operations");
                        forbear.text("Dingus & Zazzy");
                    });
                });
            });
        });
    });
}
