const std = @import("std");
const forbear = @import("forbear");

const Vec4 = @Vector(4, f32);

const theme = @import("components/theme.zig");
const ButtonProps = @import("components/button.zig").ButtonProps;
const Button = @import("components/button.zig").Button;

const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

fn readEnvBool(allocator: std.mem.Allocator, key: []const u8, default: bool) bool {
    const value = std.process.getEnvVarOwned(allocator, key) catch |err| {
        if (err != error.EnvironmentVariableNotFound) {
            std.log.warn("Failed to read env var {s}: {}", .{ key, err });
        }
        return default;
    };
    defer allocator.free(value);

    if (std.ascii.eqlIgnoreCase(value, "1") or std.ascii.eqlIgnoreCase(value, "true")) {
        return true;
    }
    if (std.ascii.eqlIgnoreCase(value, "0") or std.ascii.eqlIgnoreCase(value, "false")) {
        return false;
    }
    return default;
}

fn shouldLogFrame(frameIndex: u64) bool {
    return frameIndex < 8 or frameIndex % 120 == 0;
}

fn App() !void {
    const arena = try forbear.useArena();

    (try forbear.element(arena, .{
        .width = .grow,
        .direction = .topToBottom,
        .alignment = .topCenter,
        .background = .{ .color = theme.Colors.page },
        .font = try forbear.useFont("SpaceGrotesk"),
        .fontWeight = 400,
        .fontSize = 12.0,
        .color = theme.Colors.text,
    }))({
        try forbear.component(arena, forbear.FpsCounter, null);

        (try forbear.element(arena, .{
            .width = .grow,
            .background = .{ .color = black },
            .padding = .block(6.0),
            .alignment = .center,
        }))({
            (try forbear.element(arena, .{
                .fontWeight = 500,
                .fontSize = 10.5,
                .color = .{ 1.0, 1.0, 1.0, 1.0 },
            }))({
                // TODO: gradient background bar once gradient backgrounds are supported.
                try forbear.text(arena, "-> Book a 15 minute meeting today.");
            });
        });

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .padding = .block(6.0),
            .alignment = .center,
        }))({
            try forbear.image(arena, .{
                .width = .{ .fixed = 100.0 },
                .margin = forbear.Margin.right(24.0),
            }, try forbear.useImage("uhoh-logo"));
            (try forbear.element(arena, .{
                .width = .grow,
                .background = .{ .color = .{ 1.0, 0.0, 0.0, 1.0 } },
            }))({});
            (try forbear.element(arena, .{
                .fontWeight = 500,
                .fontSize = 10.5,
                .margin = forbear.Margin.right(13.5),
            }))({
                try forbear.text(arena, "Pricing");
            });
            try forbear.component(arena, Button, ButtonProps{
                .text = "Try it risk-free",
            });
        });

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .margin = .block(36.0),
            .direction = .leftToRight,
            .alignment = .centerLeft,
        }))({
            (try forbear.element(arena, .{
                .direction = .topToBottom,
                .width = .grow,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = 46,
                    .lineHeight = 0.75,
                    .margin = forbear.Margin.block(0.0).withBottom(18.0),
                }))({
                    try forbear.text(arena, "You're the boss, why are you still fixing tech issues?");
                });
                (try forbear.element(arena, .{
                    .fontSize = 15.0,
                    .color = black,
                    .fontWeight = 500,
                    .margin = forbear.Margin.block(12.0).withBottom(15.0),
                }))({
                    try forbear.text(arena, "It doesn't just annoy you. It slows you and your staff down. That's our job now.");
                });
                try forbear.component(arena, Button, ButtonProps{ .text = "Let us prove it*" });
                (try forbear.element(arena, .{
                    .fontSize = 9.0,
                    .color = black,
                    .margin = forbear.Margin.block(10.5).withBottom(0.0),
                }))({
                    try forbear.text(
                        arena,
                        "* You have to promise us that you'll dump all your problems on us so that we can show you what we're made of.",
                    );
                });
            });
            try forbear.image(arena, .{
                .width = .grow,
                .maxWidth = 369,
                .blendMode = .multiply,
            }, try forbear.useImage("uhoh-hero"));
        });

        const statements = [_][]const u8{
            "Less problems, more productivity",
            "Your team runs smoother",
            "A hundred things less on your plate",
        };

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = .block(22.5),
            .margin = .block(36.0),
            .borderWidth = .block(1.5),
            .borderColor = black,
        }))({
            for (statements) |statement| {
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .alignment = .centerLeft,
                    .width = .grow,
                    .fontWeight = 500,
                    .fontSize = 12.0,
                    .padding = .inLine(7.5),
                }))({
                    try forbear.image(arena, .{
                        .width = .{ .fixed = 30.0 },
                        .height = .{ .fixed = 30.0 },
                        .blendMode = .multiply,
                        .margin = .right(15.0),
                    }, try forbear.useImage("uhoh-check"));
                    try forbear.text(arena, statement);
                });
            }
        });

        const issues = [_][]const u8{
            "You got a cryptic error message on an app. Now you have to submit a ticket.",
            "Your Google ads literally just got disabled and you're not sure why. Now you have to submit a ticket.",
            "Someone on your team lost access to a shared account. Now you have to submit a ticket.",
        };

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(30.0),
        }))({
            try forbear.image(arena, .{
                .width = .grow,
                .maxWidth = 369,
                .blendMode = .multiply,
                .margin = forbear.Margin.inLine(0.0).withRight(24.0),
            }, try forbear.useImage("uhoh-problem"));
            (try forbear.element(arena, .{
                .direction = .topToBottom,
                .width = .grow,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 600,
                    .fontSize = 10.5,
                    .color = theme.Colors.muted,
                }))({
                    try forbear.text(arena, "You're a growing business.");
                });
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = 24.0,
                    .margin = forbear.Margin.block(4.5).withBottom(12.0),
                }))({
                    try forbear.text(arena, "But your day-to-day has some of this BS in it:");
                });

                for (issues, 0..) |issue, i| {
                    (try forbear.element(arena, .{
                        .direction = .leftToRight,
                        .padding = .block(9.0),
                        .fontSize = 10.5,
                        .borderWidth = if (i == 0) null else .top(1.5),
                        .borderColor = black,
                    }))({
                        try forbear.image(arena, .{
                            .width = .{ .fixed = 30.0 },
                            .height = .{ .fixed = 30.0 },
                            .blendMode = .multiply,
                            .margin = .right(7.5),
                        }, try forbear.useImage("uhoh-x-red"));
                        (try forbear.element(arena, .{ .fontSize = 12.0 }))({
                            try forbear.text(arena, issue);
                        });
                    });
                }
                (try forbear.element(arena, .{
                    .fontSize = 12.0,
                    .margin = .bottom(30.0),
                }))({
                    try forbear.text(arena, "Imagine if you could delegate all these issues to a genie?");
                });
                try forbear.component(arena, Button, ButtonProps{ .text = "Get a free trial" });
            });
        });
        const testimonials = [_]struct {
            imageId: []const u8,
            body: []const u8,
        }{
            .{
                .imageId = "uhoh-testimonial-1",
                .body = "I'll be honest, we didn't know we needed help with the IT/Tech side of our business. After bringing on uhoh, I realized that I was very wrong. In the first month we built out systems and processes that will give us the capacity to scale well past where we were targeting for this year. Bonus is any time we have a problem and hit a wall, they just fix it. It really is like having a full IT team on standby. 10/10 recommend this.\n\nClifton Sellers, Founder/CEO\nLegacy Builders",
            },
            .{
                .imageId = "uhoh-testimonial-2",
                .body = "uhoh is reliable and easy to work with. They solve complex problems quickly and bring forward smart, modern solutions that actually move the business forward. What sets them apart is how deeply they think about the company's vision, not just fixing tech issues but using technology to support growth, efficiency, and long-term impact.\n\nNa'eem Adam, Founder/CEO\nParkour, Le Burger Week",
            },
            .{
                .imageId = "uhoh-testimonial-moses",
                .body = "I had an incredible experience with uhoh. They were fast, professional, and knowledgeable. I really appreciated their transparent flat-fee pricing, which made the whole process stress-free and affordable. They handled everything with ease and went above and beyond to make sure I was satisfied. Highly recommend to anyone looking for reliable systems support!\n\nMoses Lam, Owner\nArtisanal Mortgages",
            },
            .{
                .imageId = "uhoh-testimonial-alex",
                .body = "One of the best decisions I've made as a founder. So much time saved to focus on everything else. I didn't even realize how much time I was losing previously. Highly recommend.\n\nAlex Stewart, Founder/CEO\nTeamtown",
            },
            .{
                .imageId = "uhoh-testimonial-stephanie",
                .body = "uhoh has been the solution I didn't know I needed. Deep and Erica are empathetic and care about the things I need in my business to be successful. They are working behind the scenes to help me scale without adding people. Thank you for your support!\n\nStephanie O'Brien, President\nCarmella",
            },
            .{
                .imageId = "uhoh-testimonial-enoch",
                .body = "We've been using uhoh since they started and it's been a pleasure. Great attention to detail, super proactive and always delivering value.\n\nEnoch Taralson, Director of Revenue Operations\nDingus & Zazzy",
            },
        };

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(30.0),
        }))({
            (try forbear.element(arena, .{
                .direction = .topToBottom,
                .alignment = .topCenter,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = 22.5,
                    .margin = forbear.Margin.block(0.0).withBottom(15.0),
                }))({
                    try forbear.text(arena, "Don't take our word for it.");
                });
                for (testimonials) |testimonial| {
                    (try forbear.element(arena, .{
                        .width = .grow,
                        .background = .{ .color = theme.Colors.card },
                        .borderRadius = 12.0,
                        .borderColor = theme.Colors.border,
                        .borderWidth = .all(0.75),
                        .padding = .all(13.5),
                        .margin = forbear.Margin.block(0.0).withBottom(12.0),
                        .direction = .leftToRight,
                    }))({
                        try forbear.image(arena, .{
                            .width = .{ .fixed = 80.0 },
                            .height = .{ .fixed = 80.0 },
                            .borderRadius = 12.0,
                            .margin = forbear.Margin.inLine(0.0).withRight(10.5),
                        }, try forbear.useImage(testimonial.imageId));
                        (try forbear.element(arena, .{
                            .fontSize = 11.25,
                            .lineHeight = 1.4,
                        }))({
                            try forbear.text(arena, testimonial.body);
                        });
                    });
                }
            });
        });
        const logos = [_][]const u8{
            "uhoh-partner-badge",
            "uhoh-google-logo",
            "uhoh-microsoft-logo",
            "uhoh-partner-logo",
            "uhoh-zoho-logo",
        };

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(30.0),
            .background = .{ .color = theme.Colors.soft },
        }))({
            (try forbear.element(arena, .{
                .direction = .topToBottom,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 600,
                    .fontSize = 13.5,
                    .margin = forbear.Margin.block(0.0).withBottom(13.5),
                }))({
                    try forbear.text(arena, "Our partners");
                });
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .alignment = .centerLeft,
                }))({
                    for (logos) |id| {
                        // TODO: apply a grayscale filter to these logos
                        try forbear.image(arena, .{
                            .maxWidth = 128,
                            .maxHeight = 112,
                            .margin = forbear.Margin.right(13.5),
                        }, try forbear.useImage(id));
                    }
                });
            });
        });

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(30.0),
        }))({
            (try forbear.element(arena, .{
                .direction = .topToBottom,
                .alignment = .topCenter,
            }))({
                try forbear.image(arena, .{
                    .width = .grow,
                    .maxWidth = 600,
                    .blendMode = .multiply,
                }, try forbear.useImage("uhoh-solution"));
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = 22.5,
                    .margin = forbear.Margin.block(13.5).withBottom(7.5),
                }))({
                    try forbear.text(arena, "We're here to reinvent how tech gets done.");
                });
                (try forbear.element(arena, .{
                    .fontSize = 12.0,
                    .color = theme.Colors.muted,
                    .alignment = .topCenter,
                }))({
                    try forbear.text(arena, "We're replacing clunky IT with clean, fast, and flexible support. Built for startups and teams that just want things to work.");
                });
            });
        });

        const Offering = struct {
            title: []const u8,
            imageId: []const u8,
            bullets: []const []const u8,
            addonTitle: []const u8,
            addonBody: []const u8,
        };

        const offerings = [_]Offering{
            .{
                .title = "Basic IT & Tech Support",
                .imageId = "uhoh-offer-46",
                .bullets = &[_][]const u8{
                    "Basic IT",
                    "Work space administration (Google & Microsoft)",
                    "User setup",
                    "User termination",
                    "VPN set up",
                    "Password Management & 2FA",
                    "Misfired Automations",
                    "Hardware problems",
                    "Software issues (Any tool not working correctly)",
                    "Access problems",
                    "Video meeting problems",
                    "User access",
                },
                .addonTitle = "+ Expanded IT & Tech Support",
                .addonBody = "Assisting an in house team with: device provisioning & procurement, MDM setup, printer & peripheral configuration, network diagnostics & optimization, remote desktop troubleshooting, BYOD policy setup & support, backup systems.",
            },
            .{
                .title = "Website & Domain",
                .imageId = "uhoh-offer-47",
                .bullets = &[_][]const u8{
                    "Website",
                    "Domain connection",
                    "Domain purchases",
                    "Domain monitoring",
                    "SSL Certifications",
                    "Website form integrations",
                    "Payment integrations",
                    "Website monitoring",
                    "Hosting reviews",
                    "Access problems",
                    "Video meeting problems",
                    "User access",
                },
                .addonTitle = "+ Expanded Web and Domain Support",
                .addonBody = "DNS diagnostics & hardening, speed optimization audits, accessibility & compliance testing, CDN configuration, firewall or DDoS protection setup, uptime alerts.",
            },
            .{
                .title = "Cold Email Setup & Consulting",
                .imageId = "uhoh-offer-50",
                .bullets = &[_][]const u8{
                    "Cold email consulting and setup (no production)",
                    "Set up & account management",
                    "Cold email best practices and sample copy",
                    "Cold email review",
                    "Domain management",
                    "Domain warming",
                    "How to set up lead scoring and consulting",
                },
                .addonTitle = "+ Expanded Cold Email",
                .addonBody = "Inbox rotation strategy, custom lead scoring models, ROI tracking dashboards, deliverability monitoring, pre-send risk scoring.",
            },
            .{
                .title = "CRM Management",
                .imageId = "uhoh-offer-49",
                .bullets = &[_][]const u8{
                    "CRM Management",
                    "Workflow review",
                    "Hubspot set up",
                    "Hubspot implementation",
                    "Creating booking calendars",
                    "Custom reporting",
                    "Lead scoring consulting",
                },
                .addonTitle = "+ Expanded Sales/CRM",
                .addonBody = "Pipeline automation mapping, RevOps dashboards, lead routing logic setup, referral tracking, automated commission tracking, AI enrichment of contact/company data.",
            },
            .{
                .title = "SaaS Spending, Tool Audits & Finance Ops",
                .imageId = "uhoh-offer-51",
                .bullets = &[_][]const u8{
                    "SaaS spending & tool audits",
                    "Spend audits",
                    "Tool review",
                    "Consolidation",
                    "Price negotiation",
                    "Activity logs & reporting",
                    "Float (online spending)",
                },
                .addonTitle = "+ Expanded Finance / SaaS",
                .addonBody = "Subscription lifecycle management, shadow IT detection, SaaS access control by role, expense policy workflows.",
            },
            .{
                .title = "Security Audits & Controls",
                .imageId = "uhoh-offer-53",
                .bullets = &[_][]const u8{
                    "Security audits",
                    "MFA (workspace & individual users)",
                    "Password sharing tools",
                    "SSO",
                    "Team training",
                    "Phishing training",
                },
                .addonTitle = "+ Expanded Team Training",
                .addonBody = "Device encryption setup, compliance readiness consulting, Zero Trust access implementation, vulnerability testing coordination.",
            },
        };

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(37.5),
        }))({
            (try forbear.element(arena, .{ .direction = .topToBottom }))({
                inline for (offerings) |offering| {
                    (try forbear.element(arena, .{
                        .width = .grow,
                        .background = .{ .color = theme.Colors.card },
                        .borderRadius = 12.0,
                        .borderColor = theme.Colors.border,
                        .borderWidth = .all(0.75),
                        .padding = .all(15.0),
                        .margin = forbear.Margin.block(0.0).withBottom(12.0),
                        .direction = .topToBottom,
                    }))({
                        (try forbear.element(arena, .{
                            .direction = .leftToRight,
                            .alignment = .centerLeft,
                            .margin = forbear.Margin.block(0.0).withBottom(9.0),
                        }))({
                            try forbear.image(arena, .{
                                .width = .grow,
                                .maxWidth = 100.0,
                                .blendMode = .multiply,
                                .margin = forbear.Margin.right(9.0),
                            }, try forbear.useImage(offering.imageId));
                            (try forbear.element(arena, .{
                                .fontWeight = 700,
                                .fontSize = 16.5,
                            }))({
                                try forbear.text(arena, offering.title);
                            });
                        });
                        inline for (offering.bullets) |bullet| {
                            (try forbear.element(arena, .{
                                .direction = .leftToRight,
                                .margin = forbear.Margin.block(0.0).withBottom(4.5),
                            }))({
                                (try forbear.element(arena, .{
                                    .width = .{ .fixed = 6.0 },
                                    .height = .{ .fixed = 6.0 },
                                    .background = .{ .color = theme.Colors.accentDark },
                                    .borderRadius = 3.0,
                                    .margin = forbear.Margin.inLine(0.0).withRight(7.5),
                                }))({});
                                (try forbear.element(arena, .{ .fontSize = 11.25 }))({
                                    try forbear.text(arena, bullet);
                                });
                            });
                        }
                        (try forbear.element(arena, .{
                            .background = .{ .color = theme.Colors.soft },
                            .borderRadius = 9.0,
                            .padding = .all(9.0),
                            .margin = forbear.Margin.block(10.5).withBottom(0.0),
                        }))({
                            (try forbear.element(arena, .{
                                .fontWeight = 600,
                                .fontSize = 12.0,
                                .margin = forbear.Margin.block(0.0).withBottom(4.5),
                            }))({
                                try forbear.text(arena, offering.addonTitle);
                            });
                            (try forbear.element(arena, .{
                                .fontSize = 10.5,
                                .color = theme.Colors.muted,
                            }))({
                                try forbear.text(arena, offering.addonBody);
                            });
                        });
                    });
                }
            });
        });

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(15.0).withBottom(30.0),
        }))({
            (try forbear.element(arena, .{
                .direction = .leftToRight,
            }))({
                try forbear.image(arena, .{
                    .width = .{ .fixed = 150.0 },
                    .height = .{ .fixed = 150.0 },
                    .margin = forbear.Margin.inLine(0.0).withRight(12.0),
                }, try forbear.useImage("uhoh-jon-avatar"));
                (try forbear.element(arena, .{
                    .direction = .topToBottom,
                }))({
                    (try forbear.element(arena, .{
                        .fontSize = 13.5,
                        .lineHeight = 1.4,
                    }))({
                        try forbear.text(arena, "I literally built this because I needed it for myself... it has to be fast, incredibly good and insanely affordable. It's usually impossible to get all three, but we figured it out and we're willing to go to great lengths to let you experience that for yourself.");
                    });
                    (try forbear.element(arena, .{
                        .fontSize = 10.5,
                        .color = theme.Colors.muted,
                        .margin = forbear.Margin.block(9.0).withBottom(0.0),
                    }))({
                        try forbear.text(arena, "- Jon Sturgeon, CEO of Dingus & Zazzy & Co-Founder of uhoh");
                    });
                });
            });
        });

        const benefits = [_][]const u8{
            "Faster onboarding for new hires",
            "Slack, Zoom, Email - we're already there",
            "Standardized tools + backups",
            "Clear, human support docs",
            "Less time explaining what 'ISP' means",
        };

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(30.0),
        }))({
            (try forbear.element(arena, .{
                .direction = .leftToRight,
                .alignment = .centerLeft,
            }))({
                (try forbear.element(arena, .{
                    .width = .{ .fixed = 390.0 },
                    .direction = .topToBottom,
                }))({
                    (try forbear.element(arena, .{
                        .fontWeight = 700,
                        .fontSize = 22.5,
                        .margin = forbear.Margin.block(0.0).withBottom(10.5),
                    }))({
                        try forbear.text(arena, "Your tech works. People are happy. Time comes back.");
                    });
                    inline for (benefits) |benefit| {
                        (try forbear.element(arena, .{
                            .direction = .leftToRight,
                            .margin = forbear.Margin.block(0.0).withBottom(6.0),
                            .alignment = .centerLeft,
                        }))({
                            (try forbear.element(arena, .{
                                .width = .{ .fixed = 6.0 },
                                .height = .{ .fixed = 6.0 },
                                .background = .{ .color = theme.Colors.accentDark },
                                .borderRadius = 3.0,
                                .margin = forbear.Margin.inLine(0.0).withRight(7.5),
                            }))({});
                            (try forbear.element(arena, .{ .fontSize = 12.0 }))({
                                try forbear.text(arena, benefit);
                            });
                        });
                    }
                });
                try forbear.image(arena, .{
                    .width = .grow,
                    .maxWidth = 169,
                    .blendMode = .multiply,
                    .margin = forbear.Margin.left(24.0),
                }, try forbear.useImage("uhoh-group-21"));
            });
            (try forbear.element(arena, .{
                .direction = .leftToRight,
                .alignment = .centerLeft,
                .margin = forbear.Margin.block(13.5).withBottom(0.0),
            }))({
                try forbear.image(arena, .{
                    .width = .grow,
                    .maxWidth = 169,
                    .blendMode = .multiply,
                    .margin = forbear.Margin.inLine(0.0).withRight(10.5),
                }, try forbear.useImage("uhoh-failure"));
                (try forbear.element(arena, .{
                    .fontSize = 12.0,
                    .color = theme.Colors.muted,
                }))({
                    try forbear.text(arena, "Or... keep asking your most tech-savvy employee to fix the WiFi. You could save money, time, and headaches - or keep duct-taping your IT together until it breaks.");
                });
            });
        });

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

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(30.0),
        }))({
            (try forbear.element(arena, .{ .direction = .topToBottom }))({
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = 21.0,
                    .margin = forbear.Margin.block(0.0).withBottom(13.5),
                }))({
                    try forbear.text(arena, "FAQ");
                });
                inline for (faqs) |faq| {
                    (try forbear.element(arena, .{
                        .background = .{ .color = theme.Colors.card },
                        .borderRadius = 9.0,
                        .borderColor = theme.Colors.border,
                        .borderWidth = .all(0.75),
                        .padding = .all(12.0),
                        .margin = forbear.Margin.block(0.0).withBottom(9.0),
                    }))({
                        (try forbear.element(arena, .{
                            .fontWeight = 600,
                            .fontSize = 12.0,
                            .margin = forbear.Margin.block(0.0).withBottom(6.0),
                        }))({
                            try forbear.text(arena, faq.question);
                        });
                        (try forbear.element(arena, .{
                            .fontSize = 10.5,
                            .color = theme.Colors.muted,
                        }))({
                            try forbear.text(arena, faq.answer);
                        });
                    });
                }
                // TODO: interactive accordion behaviour for FAQ items when event-driven toggles per element are available.
            });
        });

        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .alignment = .topCenter,
            .padding = forbear.Padding.top(22.5).withBottom(37.5),
        }))({
            (try forbear.element(arena, .{
                .direction = .topToBottom,
                .alignment = .topCenter,
            }))({
                try forbear.image(arena, .{
                    .height = .{ .fixed = 200.0 },
                    .blendMode = .multiply,
                }, try forbear.useImage("uhoh-bottom-cta"));
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = 22.5,
                    .margin = forbear.Margin.block(13.5).withBottom(7.5),
                }))({
                    try forbear.text(arena, "Dude, you're at the bottom of our landing page.");
                });
                (try forbear.element(arena, .{
                    .fontSize = 12.0,
                    .color = theme.Colors.muted,
                    .margin = forbear.Margin.block(0.0).withBottom(20.0),
                }))({
                    try forbear.text(arena, "Just get the free trial already if you're that interested. You scrolled all the way here.");
                });

                // TODO: make component slotting work so we can include the
                // "Don't make me beg" sub text here
                try forbear.component(arena, Button, ButtonProps{ .text = "Come on, click on this" });
            });
        });
        (try forbear.element(arena, .{
            .width = .grow,
            .maxWidth = 810.0,
            .background = .{ .color = theme.Colors.soft },
            .alignment = .topCenter,
            .padding = forbear.Padding.top(15.0).withBottom(19.5),
        }))({
            (try forbear.element(arena, .{
                .direction = .topToBottom,
            }))({
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .alignment = .center,
                }))({
                    try forbear.image(arena, .{
                        .width = .{ .fixed = 90.0 },
                        .margin = forbear.Margin.right(9.0),
                    }, try forbear.useImage("uhoh-logo"));
                    (try forbear.element(arena, .{ .fontSize = 9.0 }))({
                        try forbear.text(arena, "Privacy Policy");
                    });
                });
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .margin = forbear.Margin.block(12.0).withBottom(0.0),
                }))({
                    (try forbear.element(arena, .{
                        .fontSize = 9.0,
                        .color = theme.Colors.muted,
                        .margin = forbear.Margin.inLine(0.0).withRight(15.0),
                    }))({
                        try forbear.text(arena, "© 2025 uhoh. All rights reserved.");
                    });
                    (try forbear.element(arena, .{
                        .fontSize = 9.0,
                        .color = theme.Colors.muted,
                    }))({
                        try forbear.text(arena, "Designed by your lover, Loogart");
                    });
                });
            });
        });
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    renderer: *forbear.Graphics.Renderer,
    window: *const forbear.Window,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.registerFont("SpaceGrotesk", @embedFile("SpaceGrotesk.ttf"));

    try forbear.registerImage("uhoh-logo", @embedFile("static/uhoh-logo.png"), .png);
    try forbear.registerImage("uhoh-hero", @embedFile("static/uhoh-hero.png"), .png);
    try forbear.registerImage("uhoh-check", @embedFile("static/uhoh-check.png"), .png);
    try forbear.registerImage("uhoh-problem", @embedFile("static/uhoh-problem.png"), .png);
    try forbear.registerImage("uhoh-x-red", @embedFile("static/uhoh-x-red.png"), .png);
    try forbear.registerImage("uhoh-testimonial-1", @embedFile("static/uhoh-testimonial-1.png"), .png);
    try forbear.registerImage("uhoh-testimonial-2", @embedFile("static/uhoh-testimonial-2.png"), .png);
    try forbear.registerImage("uhoh-testimonial-moses", @embedFile("static/uhoh-testimonial-moses.png"), .png);
    try forbear.registerImage("uhoh-testimonial-alex", @embedFile("static/uhoh-testimonial-alex.png"), .png);
    try forbear.registerImage("uhoh-testimonial-stephanie", @embedFile("static/uhoh-testimonial-stephanie.png"), .png);
    try forbear.registerImage("uhoh-testimonial-enoch", @embedFile("static/uhoh-testimonial-enoch.png"), .png);
    try forbear.registerImage("uhoh-partner-badge", @embedFile("static/uhoh-partner-badge.png"), .png);
    try forbear.registerImage("uhoh-google-logo", @embedFile("static/uhoh-google-logo.png"), .png);
    try forbear.registerImage("uhoh-microsoft-logo", @embedFile("static/uhoh-microsoft-logo.png"), .png);
    try forbear.registerImage("uhoh-partner-logo", @embedFile("static/uhoh-partner-logo.png"), .png);
    try forbear.registerImage("uhoh-zoho-logo", @embedFile("static/uhoh-zoho-logo.png"), .png);
    try forbear.registerImage("uhoh-solution", @embedFile("static/uhoh-solution.png"), .png);
    try forbear.registerImage("uhoh-offer-46", @embedFile("static/uhoh-offer-46.png"), .png);
    try forbear.registerImage("uhoh-offer-47", @embedFile("static/uhoh-offer-47.png"), .png);
    try forbear.registerImage("uhoh-offer-50", @embedFile("static/uhoh-offer-50.png"), .png);
    try forbear.registerImage("uhoh-offer-49", @embedFile("static/uhoh-offer-49.png"), .png);
    try forbear.registerImage("uhoh-offer-51", @embedFile("static/uhoh-offer-51.png"), .png);
    try forbear.registerImage("uhoh-offer-53", @embedFile("static/uhoh-offer-53.png"), .png);
    try forbear.registerImage("uhoh-jon-avatar", @embedFile("static/uhoh-jon-avatar.png"), .png);
    try forbear.registerImage("uhoh-how-it-works", @embedFile("static/uhoh-how-it-works.png"), .png);
    try forbear.registerImage("uhoh-group-21", @embedFile("static/uhoh-group-21.png"), .png);
    try forbear.registerImage("uhoh-failure", @embedFile("static/uhoh-failure.png"), .png);
    try forbear.registerImage("uhoh-bottom-cta", @embedFile("static/uhoh-bottom-cta.png"), .png);

    const layoutDebugEnabled = readEnvBool(allocator, "FORBEAR_LAYOUT_DEBUG", false);
    if (layoutDebugEnabled) {
        std.log.info("FORBEAR_LAYOUT_DEBUG enabled for uhoh.com frame diagnostics", .{});
    }

    var frameIndex: u64 = 0;
    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);
        const shouldLog = layoutDebugEnabled and shouldLogFrame(frameIndex);
        var frameStartNs: i128 = 0;
        if (shouldLog) {
            frameStartNs = std.time.nanoTimestamp();
            std.log.debug("[uhoh-layout-debug] frame={} start", .{frameIndex});
        }

        try forbear.component(arena, App, null);

        const viewportSize = renderer.viewportSize();
        var layoutStartNs: i128 = 0;
        if (shouldLog) {
            layoutStartNs = std.time.nanoTimestamp();
            std.log.debug("[uhoh-layout-debug] frame={} before layout viewport={any} dpi={any}", .{ frameIndex, viewportSize, window.dpi });
        }

        const rootLayoutBox = try forbear.layout(
            arena,
            .{
                .font = try forbear.useFont("SpaceGrotesk"),
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .textWrapping = .word,
                .fontWeight = 400,
                .lineHeight = 1.0,
                .blendMode = .normal,
            },
            viewportSize,
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
        );
        if (shouldLog) {
            const layoutMs: f64 = @as(f64, @floatFromInt(std.time.nanoTimestamp() - layoutStartNs)) / 1_000_000.0;
            std.log.debug(
                "[uhoh-layout-debug] frame={} after layout: {d:.3}ms rootPos={any} rootSize={any}",
                .{ frameIndex, layoutMs, rootLayoutBox.position, rootLayoutBox.size },
            );
        }

        var drawStartNs: i128 = 0;
        if (shouldLog) {
            drawStartNs = std.time.nanoTimestamp();
        }
        try renderer.drawFrame(arena, &[_]forbear.LayoutBox{rootLayoutBox}, .{ 0.99, 0.98, 0.96, 1.0 }, window.dpi, window.targetFrameTimeNs());
        if (shouldLog) {
            const drawMs: f64 = @as(f64, @floatFromInt(std.time.nanoTimestamp() - drawStartNs)) / 1_000_000.0;
            std.log.debug("[uhoh-layout-debug] frame={} after drawFrame: {d:.3}ms", .{ frameIndex, drawMs });
        }

        var updateStartNs: i128 = 0;
        if (shouldLog) {
            updateStartNs = std.time.nanoTimestamp();
        }
        try forbear.update(arena, &rootLayoutBox, viewportSize);
        if (shouldLog) {
            const updateMs: f64 = @as(f64, @floatFromInt(std.time.nanoTimestamp() - updateStartNs)) / 1_000_000.0;
            const totalMs: f64 = @as(f64, @floatFromInt(std.time.nanoTimestamp() - frameStartNs)) / 1_000_000.0;
            std.log.debug(
                "[uhoh-layout-debug] frame={} after update: {d:.3}ms total={d:.3}ms",
                .{ frameIndex, updateMs, totalMs },
            );
        }

        forbear.resetNodeTree();
        frameIndex += 1;
    }
    try renderer.waitIdle();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Memory was leaked", .{});
        }
    }

    const allocator = gpa.allocator();

    var graphics = try forbear.Graphics.init(
        allocator,
        "forbear playground",
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        allocator,
        1280,
        720,
        "uhoh.com",
        "uhoh.com",
    );
    defer window.deinit();

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();

    try forbear.init(allocator, &renderer);
    defer forbear.deinit();
    forbear.setWindowHandlers(window);

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            &renderer,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
