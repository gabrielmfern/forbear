const std = @import("std");
const forbear = @import("forbear");

const theme = @import("components/theme.zig");
const ButtonProps = @import("components/button.zig").ButtonProps;
const Button = @import("components/button.zig").Button;

fn App() !void {
    const arena = try forbear.useArena();

    try forbear.component(arena, forbear.FpsCounter, null);

    (try forbear.element(arena, .{
        .preferredWidth = .grow,
        .direction = .topToBottom,
        .horizontalAlignment = .center,
        .background = .{ .color = theme.Colors.page },
        .font = try forbear.useFont("SpaceGrotesk"),
        .fontWeight = 400,
        .fontSize = theme.pxInt(16.0),
        .lineHeight = 1.3,
        .color = theme.Colors.text,
    }))({
        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .background = .{ .color = theme.Colors.accent },
            .paddingBlock = .{ theme.px(8.0), theme.px(8.0) },
            .horizontalAlignment = .center,
            .verticalAlignment = .center,
        }))({
            (try forbear.element(arena, .{
                .fontWeight = 500,
                .fontSize = theme.pxInt(14.0),
                .color = .{ 1.0, 1.0, 1.0, 1.0 },
            }))({
                // TODO: gradient background bar once gradient backgrounds are supported.
                try forbear.text(arena, "-> Book a 15 minute meeting today.");
            });
        });

        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(18.0), theme.px(18.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .leftToRight,
                .horizontalAlignment = .start,
                .verticalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(90.0) },
                    .preferredHeight = .{ .fixed = theme.px(28.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-logo") },
                    .marginInline = .{ 0.0, theme.px(32.0) },
                }))({});
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .horizontalAlignment = .end,
                    .verticalAlignment = .center,
                }))({
                    (try forbear.element(arena, .{
                        .fontWeight = 500,
                        .fontSize = theme.pxInt(14.0),
                        .marginInline = .{ 0.0, theme.px(18.0) },
                    }))({
                        try forbear.text(arena, "Pricing");
                    });
                    // TODO: responsive hamburger nav for smaller widths.
                    (try forbear.element(arena, .{
                        .background = .{ .color = theme.Colors.accent },
                        .borderRadius = theme.px(10.0),
                        .paddingBlock = .{ theme.px(10.0), theme.px(10.0) },
                        .paddingInline = .{ theme.px(18.0), theme.px(18.0) },
                        .horizontalAlignment = .center,
                        .verticalAlignment = .center,
                    }))({
                        (try forbear.element(arena, .{
                            .fontWeight = 600,
                            .fontSize = theme.pxInt(14.0),
                            .color = .{ 1.0, 1.0, 1.0, 1.0 },
                        }))({
                            try forbear.text(arena, "Get a free trial");
                        });
                    });
                });
            });
        });
        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(50.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = wideWidth },
                .direction = .leftToRight,
                .horizontalAlignment = .start,
                .verticalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(520.0) },
                    .direction = .topToBottom,
                }))({
                    (try forbear.element(arena, .{
                        .fontWeight = 700,
                        .fontSize = theme.pxInt(46.0),
                        .lineHeight = 1.05,
                    }))({
                        // TODO: typewriter animation for this heading when animations for text are available.
                        try forbear.text(arena, "You're the boss, why are you still fixing tech issues?");
                    });
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(20.0),
                        .color = theme.Colors.muted,
                        .marginBlock = .{ theme.px(16.0), theme.px(20.0) },
                    }))({
                        try forbear.text(arena, "It doesn't just annoy you. It slows you and your staff down. That's our job now.");
                    });
                    try forbear.component(arena, Button, ButtonProps{ .text = "Let us prove it*" });
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(12.0),
                        .color = theme.Colors.muted,
                        .marginBlock = .{ theme.px(14.0), 0.0 },
                        .preferredWidth = .{ .fixed = theme.px(360.0) },
                    }))({
                        try forbear.text(
                            arena,
                            "* You have to promise us that you'll dump all your problems on us so that we can show you what we're made of.",
                        );
                    });
                });
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(360.0) },
                    .preferredHeight = .{ .fixed = theme.px(380.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-hero") },
                }))({});
            });
        });

        const statements = [_][]const u8{
            "Less problems, more productivity",
            "Your team runs smoother",
            "A hundred things less on your plate",
        };

        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(16.0), theme.px(32.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .leftToRight,
                .horizontalAlignment = .start,
            }))({
                inline for (statements) |statement| {
                    (try forbear.element(arena, .{
                        .preferredWidth = .{ .fixed = theme.px(300.0) },
                        .direction = .leftToRight,
                        .verticalAlignment = .center,
                        .marginInline = .{ 0.0, theme.px(24.0) },
                    }))({
                        (try forbear.element(arena, .{
                            .preferredWidth = .{ .fixed = theme.px(22.0) },
                            .preferredHeight = .{ .fixed = theme.px(22.0) },
                            .background = .{ .image = try forbear.useImage("uhoh-check") },
                            .marginInline = .{ 0.0, theme.px(10.0) },
                        }))({});
                        (try forbear.element(arena, .{
                            .fontWeight = 500,
                            .fontSize = theme.pxInt(16.0),
                        }))({
                            try forbear.text(arena, statement);
                        });
                    });
                }
            });
        });

        const issues = [_][]const u8{
            "You got a cryptic error message on an app. Now you have to submit a ticket.",
            "Your Google ads literally just got disabled and you're not sure why. Now you have to submit a ticket.",
            "Someone on your team lost access to a shared account. Now you have to submit a ticket.",
        };

        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = wideWidth },
                .direction = .leftToRight,
                .horizontalAlignment = .start,
                .verticalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(320.0) },
                    .preferredHeight = .{ .fixed = theme.px(340.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-problem") },
                    .marginInline = .{ 0.0, theme.px(32.0) },
                }))({});
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(520.0) },
                    .direction = .topToBottom,
                }))({
                    (try forbear.element(arena, .{
                        .fontWeight = 600,
                        .fontSize = theme.pxInt(14.0),
                        .color = theme.Colors.muted,
                    }))({
                        try forbear.text(arena, "You're a growing business.");
                    });
                    (try forbear.element(arena, .{
                        .fontWeight = 700,
                        .fontSize = theme.pxInt(32.0),
                        .marginBlock = .{ theme.px(6.0), theme.px(16.0) },
                    }))({
                        try forbear.text(arena, "But your day-to-day has some of this BS in it:");
                    });

                    for (issues) |issue| {
                        (try forbear.element(arena, .{
                            .direction = .leftToRight,
                            .verticalAlignment = .start,
                            .marginBlock = .{ 0.0, theme.px(10.0) },
                        }))({
                            (try forbear.element(arena, .{
                                .preferredWidth = .{ .fixed = theme.px(18.0) },
                                .preferredHeight = .{ .fixed = theme.px(18.0) },
                                .background = .{ .image = try forbear.useImage("uhoh-x-red") },
                                .marginInline = .{ 0.0, theme.px(10.0) },
                            }))({});
                            (try forbear.element(arena, .{ .fontSize = theme.pxInt(16.0) }))({
                                try forbear.text(arena, issue);
                            });
                        });
                    }
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(16.0),
                        .marginBlock = .{ theme.px(16.0), theme.px(20.0) },
                    }))({
                        try forbear.text(arena, "Imagine if you could delegate all these issues to a genie?");
                    });
                    try forbear.component(arena, Button, ButtonProps{ .text = "Get a free trial" });
                });
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
                .horizontalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = theme.pxInt(30.0),
                    .marginBlock = .{ 0.0, theme.px(20.0) },
                }))({
                    try forbear.text(arena, "Don't take our word for it.");
                });
                inline for (testimonials) |testimonial| {
                    (try forbear.element(arena, .{
                        .preferredWidth = .grow,
                        .background = .{ .color = theme.Colors.card },
                        .borderRadius = theme.px(16.0),
                        .borderColor = theme.Colors.border,
                        .borderInlineWidth = @splat(theme.px(1.0)),
                        .borderBlockWidth = @splat(theme.px(1.0)),
                        .paddingBlock = .{ theme.px(18.0), theme.px(18.0) },
                        .paddingInline = .{ theme.px(18.0), theme.px(18.0) },
                        .marginBlock = .{ 0.0, theme.px(16.0) },
                        .direction = .leftToRight,
                    }))({
                        (try forbear.element(arena, .{
                            .preferredWidth = .{ .fixed = theme.px(56.0) },
                            .preferredHeight = .{ .fixed = theme.px(56.0) },
                            .background = .{ .image = try forbear.useImage(testimonial.imageId) },
                            .borderRadius = theme.px(28.0),
                            .marginInline = .{ 0.0, theme.px(14.0) },
                        }))({});
                        (try forbear.element(arena, .{
                            .fontSize = theme.pxInt(15.0),
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
            .background = .{ .color = theme.Colors.soft },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 600,
                    .fontSize = theme.pxInt(18.0),
                    .marginBlock = .{ 0.0, theme.px(18.0) },
                }))({
                    try forbear.text(arena, "Our partners");
                });
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .horizontalAlignment = .start,
                    .verticalAlignment = .center,
                }))({
                    for (logos) |id| {
                        (try forbear.element(arena, .{
                            .preferredWidth = .{ .fixed = theme.px(160.0) },
                            .preferredHeight = .{ .fixed = theme.px(56.0) },
                            .background = .{ .image = try forbear.useImage(id) },
                            .marginInline = .{ 0.0, theme.px(18.0) },
                        }))({});
                    }
                });
            });
        });

        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
                .horizontalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(360.0) },
                    .preferredHeight = .{ .fixed = theme.px(220.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-solution") },
                }))({});
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = theme.pxInt(30.0),
                    .marginBlock = .{ theme.px(18.0), theme.px(10.0) },
                }))({
                    try forbear.text(arena, "We're here to reinvent how tech gets done.");
                });
                (try forbear.element(arena, .{
                    .fontSize = theme.pxInt(16.0),
                    .color = theme.Colors.muted,
                    .preferredWidth = .{ .fixed = theme.px(540.0) },
                    .horizontalAlignment = .center,
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(50.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = wideWidth },
                .direction = .topToBottom,
            }))({
                inline for (offerings) |offering| {
                    (try forbear.element(arena, .{
                        .preferredWidth = .grow,
                        .background = .{ .color = theme.Colors.card },
                        .borderRadius = theme.px(16.0),
                        .borderColor = theme.Colors.border,
                        .borderInlineWidth = @splat(theme.px(1.0)),
                        .borderBlockWidth = @splat(theme.px(1.0)),
                        .paddingBlock = .{ theme.px(20.0), theme.px(20.0) },
                        .paddingInline = .{ theme.px(20.0), theme.px(20.0) },
                        .marginBlock = .{ 0.0, theme.px(16.0) },
                        .direction = .topToBottom,
                    }))({
                        (try forbear.element(arena, .{
                            .direction = .leftToRight,
                            .verticalAlignment = .center,
                            .marginBlock = .{ 0.0, theme.px(12.0) },
                        }))({
                            (try forbear.element(arena, .{
                                .preferredWidth = .{ .fixed = theme.px(40.0) },
                                .preferredHeight = .{ .fixed = theme.px(40.0) },
                                .background = .{ .image = try forbear.useImage(offering.imageId) },
                                .marginInline = .{ 0.0, theme.px(12.0) },
                            }))({});
                            (try forbear.element(arena, .{
                                .fontWeight = 700,
                                .fontSize = theme.pxInt(22.0),
                            }))({
                                try forbear.text(arena, offering.title);
                            });
                        });
                        inline for (offering.bullets) |bullet| {
                            (try forbear.element(arena, .{
                                .direction = .leftToRight,
                                .verticalAlignment = .start,
                                .marginBlock = .{ 0.0, theme.px(6.0) },
                            }))({
                                (try forbear.element(arena, .{
                                    .preferredWidth = .{ .fixed = theme.px(8.0) },
                                    .preferredHeight = .{ .fixed = theme.px(8.0) },
                                    .background = .{ .color = theme.Colors.accentDark },
                                    .borderRadius = theme.px(4.0),
                                    .marginInline = .{ 0.0, theme.px(10.0) },
                                }))({});
                                (try forbear.element(arena, .{ .fontSize = theme.pxInt(15.0) }))({
                                    try forbear.text(arena, bullet);
                                });
                            });
                        }
                        (try forbear.element(arena, .{
                            .background = .{ .color = theme.Colors.soft },
                            .borderRadius = theme.px(12.0),
                            .paddingBlock = .{ theme.px(12.0), theme.px(12.0) },
                            .paddingInline = .{ theme.px(12.0), theme.px(12.0) },
                            .marginBlock = .{ theme.px(14.0), 0.0 },
                        }))({
                            (try forbear.element(arena, .{
                                .fontWeight = 600,
                                .fontSize = theme.pxInt(16.0),
                                .marginBlock = .{ 0.0, theme.px(6.0) },
                            }))({
                                try forbear.text(arena, offering.addonTitle);
                            });
                            (try forbear.element(arena, .{
                                .fontSize = theme.pxInt(14.0),
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(20.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .leftToRight,
                .verticalAlignment = .start,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(80.0) },
                    .preferredHeight = .{ .fixed = theme.px(80.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-jon-avatar") },
                    .borderRadius = theme.px(40.0),
                    .marginInline = .{ 0.0, theme.px(16.0) },
                }))({});
                (try forbear.element(arena, .{
                    .direction = .topToBottom,
                }))({
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(18.0),
                        .lineHeight = 1.4,
                    }))({
                        try forbear.text(arena, "I literally built this because I needed it for myself... it has to be fast, incredibly good and insanely affordable. It's usually impossible to get all three, but we figured it out and we're willing to go to great lengths to let you experience that for yourself.");
                    });
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(14.0),
                        .color = theme.Colors.muted,
                        .marginBlock = .{ theme.px(12.0), 0.0 },
                    }))({
                        try forbear.text(arena, "- Jon Sturgeon, CEO of Dingus & Zazzy & Co-Founder of uhoh");
                    });
                });
            });
        });

        const steps = [_][]const u8{
            "Subscribe monthly (starting at $3k/mo, up to 50 staff).",
            "Get onboarding + access to your support pod.",
            "Enjoy fast, human answers + proactive IT.",
        };

        const step_numbers = [_][]const u8{ "1", "2", "3" };

        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
                .horizontalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(220.0) },
                    .preferredHeight = .{ .fixed = theme.px(180.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-how-it-works") },
                }))({});
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = theme.pxInt(28.0),
                    .marginBlock = .{ theme.px(18.0), theme.px(18.0) },
                }))({
                    try forbear.text(arena, "Your new IT department. On demand.");
                });
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .horizontalAlignment = .start,
                }))({
                    inline for (steps, 0..) |step, index| {
                        (try forbear.element(arena, .{
                            .preferredWidth = .{ .fixed = theme.px(300.0) },
                            .direction = .topToBottom,
                            .marginInline = .{ 0.0, theme.px(24.0) },
                        }))({
                            (try forbear.element(arena, .{
                                .fontWeight = 700,
                                .fontSize = theme.pxInt(20.0),
                                .marginBlock = .{ 0.0, theme.px(6.0) },
                            }))({
                                const label = step_numbers[index];
                                try forbear.text(arena, label);
                            });
                            (try forbear.element(arena, .{ .fontSize = theme.pxInt(16.0) }))({
                                try forbear.text(arena, step);
                            });
                        });
                    }
                });
                (try forbear.element(arena, .{ .marginBlock = .{ theme.px(20.0), 0.0 } }))({
                    (try forbear.element(arena, .{
                        .background = .{ .color = theme.Colors.accent },
                        .borderRadius = theme.px(10.0),
                        .paddingBlock = .{ theme.px(12.0), theme.px(12.0) },
                        .paddingInline = .{ theme.px(24.0), theme.px(24.0) },
                        .horizontalAlignment = .center,
                        .verticalAlignment = .center,
                    }))({
                        (try forbear.element(arena, .{
                            .fontWeight = 600,
                            .fontSize = theme.pxInt(16.0),
                            .color = .{ 1.0, 1.0, 1.0, 1.0 },
                        }))({
                            try forbear.text(arena, "Start today (30-Day Money Back Guarantee)");
                        });
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = wideWidth },
                .direction = .leftToRight,
                .horizontalAlignment = .start,
                .verticalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(520.0) },
                    .direction = .topToBottom,
                }))({
                    (try forbear.element(arena, .{
                        .fontWeight = 700,
                        .fontSize = theme.pxInt(30.0),
                        .marginBlock = .{ 0.0, theme.px(14.0) },
                    }))({
                        try forbear.text(arena, "Your tech works. People are happy. Time comes back.");
                    });
                    inline for (benefits) |benefit| {
                        (try forbear.element(arena, .{
                            .direction = .leftToRight,
                            .marginBlock = .{ 0.0, theme.px(8.0) },
                            .verticalAlignment = .center,
                        }))({
                            (try forbear.element(arena, .{
                                .preferredWidth = .{ .fixed = theme.px(8.0) },
                                .preferredHeight = .{ .fixed = theme.px(8.0) },
                                .background = .{ .color = theme.Colors.accentDark },
                                .borderRadius = theme.px(4.0),
                                .marginInline = .{ 0.0, theme.px(10.0) },
                            }))({});
                            (try forbear.element(arena, .{ .fontSize = theme.pxInt(16.0) }))({
                                try forbear.text(arena, benefit);
                            });
                        });
                    }
                });
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(360.0) },
                    .preferredHeight = .{ .fixed = theme.px(300.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-group-21") },
                    .marginInline = .{ theme.px(32.0), 0.0 },
                }))({});
            });
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .leftToRight,
                .verticalAlignment = .center,
                .marginBlock = .{ theme.px(18.0), 0.0 },
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(120.0) },
                    .preferredHeight = .{ .fixed = theme.px(80.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-failure") },
                    .marginInline = .{ 0.0, theme.px(14.0) },
                }))({});
                (try forbear.element(arena, .{
                    .fontSize = theme.pxInt(16.0),
                    .color = theme.Colors.muted,
                }))({
                    try forbear.text(arena, "Or keep asking your most tech-savvy employee to fix the WiFi. You could save money, time, and headaches - or keep duct-taping your IT together until it breaks.");
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(40.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
            }))({
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = theme.pxInt(28.0),
                    .marginBlock = .{ 0.0, theme.px(18.0) },
                }))({
                    try forbear.text(arena, "FAQ");
                });
                inline for (faqs) |faq| {
                    (try forbear.element(arena, .{
                        .background = .{ .color = theme.Colors.card },
                        .borderRadius = theme.px(12.0),
                        .borderColor = theme.Colors.border,
                        .borderInlineWidth = @splat(theme.px(1.0)),
                        .borderBlockWidth = @splat(theme.px(1.0)),
                        .paddingBlock = .{ theme.px(16.0), theme.px(16.0) },
                        .paddingInline = .{ theme.px(16.0), theme.px(16.0) },
                        .marginBlock = .{ 0.0, theme.px(12.0) },
                    }))({
                        (try forbear.element(arena, .{
                            .fontWeight = 600,
                            .fontSize = theme.pxInt(16.0),
                            .marginBlock = .{ 0.0, theme.px(8.0) },
                        }))({
                            try forbear.text(arena, faq.question);
                        });
                        (try forbear.element(arena, .{
                            .fontSize = theme.pxInt(14.0),
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
            .preferredWidth = .{ .fixed = 1080 },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(30.0), theme.px(50.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
                .horizontalAlignment = .center,
            }))({
                (try forbear.element(arena, .{
                    .preferredWidth = .{ .fixed = theme.px(420.0) },
                    .preferredHeight = .{ .fixed = theme.px(240.0) },
                    .background = .{ .image = try forbear.useImage("uhoh-bottom-cta") },
                }))({});
                (try forbear.element(arena, .{
                    .fontWeight = 700,
                    .fontSize = theme.pxInt(30.0),
                    .marginBlock = .{ theme.px(18.0), theme.px(10.0) },
                }))({
                    try forbear.text(arena, "Dude, you're at the bottom of our landing page.");
                });
                (try forbear.element(arena, .{
                    .fontSize = theme.pxInt(16.0),
                    .color = theme.Colors.muted,
                    .marginBlock = .{ 0.0, 20.0 },
                }))({
                    try forbear.text(arena, "Just get the free trial already if you're that interested. You scrolled all the way here.");
                });

                // TODO: make component slotting work so we can include the
                // "Don't make me beg" sub text here
                try forbear.component(arena, Button, ButtonProps{ .text = "Come on, click on this" });
            });
        });
        (try forbear.element(arena, .{
            .preferredWidth = .{ .fixed = 1080 },
            .background = .{ .color = theme.Colors.soft },
            .horizontalAlignment = .center,
            .paddingBlock = .{ theme.px(20.0), theme.px(26.0) },
        }))({
            (try forbear.element(arena, .{
                // .preferredWidth = .{ .fixed = maxWidth },
                .direction = .topToBottom,
            }))({
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .verticalAlignment = .center,
                }))({
                    (try forbear.element(arena, .{
                        .preferredWidth = .{ .fixed = theme.px(90.0) },
                        .preferredHeight = .{ .fixed = theme.px(28.0) },
                        .background = .{ .image = try forbear.useImage("uhoh-logo") },
                        .marginInline = .{ 0.0, theme.px(12.0) },
                    }))({});
                    (try forbear.element(arena, .{ .fontSize = theme.pxInt(12.0) }))({
                        try forbear.text(arena, "Privacy Policy");
                    });
                });
                (try forbear.element(arena, .{
                    .direction = .leftToRight,
                    .horizontalAlignment = .start,
                    .marginBlock = .{ theme.px(16.0), 0.0 },
                }))({
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(12.0),
                        .color = theme.Colors.muted,
                        .marginInline = .{ 0.0, theme.px(20.0) },
                    }))({
                        try forbear.text(arena, "© 2025 uhoh. All rights reserved.");
                    });
                    (try forbear.element(arena, .{
                        .fontSize = theme.pxInt(12.0),
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

    // Image registrations for uhoh.com layout
    try forbear.registerImage("uhoh-logo", @embedFile("static/6866e1f2f5db9ee9aafa5d7a_logo%20simple%20uhoh.png"), .png);
    try forbear.registerImage("uhoh-hero", @embedFile("static/6866e24ffd32a1a430a254a8_hero%20genie.png"), .png);
    try forbear.registerImage("uhoh-check", @embedFile("static/6839de52b9ef2a42b344edfd_check%20mark%20green.png"), .png);
    try forbear.registerImage("uhoh-problem", @embedFile("static/6839de537624ed14a719d8f3_problem.png"), .png);
    try forbear.registerImage("uhoh-x-red", @embedFile("static/6839de525b136144e236cfae_x%20red.png"), .png);
    try forbear.registerImage("uhoh-testimonial-1", @embedFile("static/6839de52571827f6f40dce2e_testimonial%201.png"), .png);
    try forbear.registerImage("uhoh-testimonial-2", @embedFile("static/683a841cc0ff2b611c4712cd_1692617660614.png"), .png);
    try forbear.registerImage("uhoh-testimonial-moses", @embedFile("static/68dc1100b21bf5c9f12feb4b_Moses.png"), .png);
    try forbear.registerImage("uhoh-testimonial-alex", @embedFile("static/68dc10dc1d80e7512b86a59c_Alex.png"), .png);
    try forbear.registerImage("uhoh-testimonial-stephanie", @embedFile("static/68dc10f4a5f41b9c533efb64_Stephanie.png"), .png);
    try forbear.registerImage("uhoh-testimonial-enoch", @embedFile("static/68dc18cf3463b42d907cbad2_enoch%20smoking-20.png"), .png);
    try forbear.registerImage("uhoh-partner-badge", @embedFile("static/6887ccdcceef4ce74922f28d_partner-badge-color.png"), .png);
    try forbear.registerImage("uhoh-google-logo", @embedFile("static/6887cdd83980b0eb55153ff8_Google%202015%20Logo.png"), .png);
    try forbear.registerImage("uhoh-microsoft-logo", @embedFile("static/6887ce1645602ebfc60604a1_Microsoft%20Logo%202012.png"), .png);
    try forbear.registerImage("uhoh-partner-logo", @embedFile("static/68dc19265ee1bddc2beacfce_logo.png"), .png);
    try forbear.registerImage("uhoh-zoho-logo", @embedFile("static/6887ce2d2b1e71bca0d7c3e0_Zoho%20Logo%202023.png"), .png);
    try forbear.registerImage("uhoh-solution", @embedFile("static/6839de5260bd5f09ac1d4c04_solution.png"), .png);
    try forbear.registerImage("uhoh-offer-46", @embedFile("static/6887d46e661f2c6c886de440_image%2046.png"), .png);
    try forbear.registerImage("uhoh-offer-47", @embedFile("static/6887d46e21d194b42c4d578e_image%2047.png"), .png);
    try forbear.registerImage("uhoh-offer-50", @embedFile("static/6887d46e617ef31b88670ddc_image%2050.png"), .png);
    try forbear.registerImage("uhoh-offer-49", @embedFile("static/6887d46edc5b564755bf39db_image%2049.png"), .png);
    try forbear.registerImage("uhoh-offer-51", @embedFile("static/6887d46e4fc6f6dd34403d0c_image%2051.png"), .png);
    try forbear.registerImage("uhoh-offer-53", @embedFile("static/6887d46e69c172360a248ec7_image%2053.png"), .png);
    try forbear.registerImage("uhoh-jon-avatar", @embedFile("static/6839de5260bd5f09ac1d4be3_jon%20sturgeon%20avatar.png"), .png);
    try forbear.registerImage("uhoh-how-it-works", @embedFile("static/6839de520709f5e6039d6426_how%20it%20works.png"), .png);
    try forbear.registerImage("uhoh-group-21", @embedFile("static/6866eaee9e1b6f866ec51700_Group%2021.png"), .png);
    try forbear.registerImage("uhoh-failure", @embedFile("static/6839de527c6db7ab25880f81_failure%20statement.png"), .png);
    try forbear.registerImage("uhoh-bottom-cta", @embedFile("static/6866e71baffe39601803502b_6BB3AB81-8718-47EF-8AA6-BF58C1A5FC65.png"), .png);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.component(arena, App, null);

        const viewportSize = renderer.viewportSize();
        const layoutBoxes = try forbear.layout(
            arena,
            .{
                .font = try forbear.useFont("SpaceGrotesk"),
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .textWrapping = .word,
                .fontWeight = 400,
                .lineHeight = 1.0,
            },
            viewportSize,
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
        );
        try renderer.drawFrame(arena, layoutBoxes, .{ 0.99, 0.98, 0.96, 1.0 }, window.dpi, window.targetFrameTimeNs());
        try forbear.update(arena, layoutBoxes, viewportSize);

        forbear.resetNodeTree();
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
        800,
        600,
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
