const std = @import("std");
const builtin = @import("builtin");
const forbear = @import("forbear");

const Vec4 = @Vector(4, f32);

const Colors = @import("colors.zig");
const Button = @import("components/button.zig").Button;
const Testimonial = @import("components/testimonial.zig").Testimonial;

const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

const rainbowBar = [_]forbear.GradientStop{
    .{ .color = forbear.hex("ff6b9d"), .position = 0.0 },
    .{ .color = forbear.hex("ffb066"), .position = 0.18 },
    .{ .color = forbear.hex("fff066"), .position = 0.36 },
    .{ .color = forbear.hex("9bf088"), .position = 0.54 },
    .{ .color = forbear.hex("6bc7ff"), .position = 0.72 },
    .{ .color = forbear.hex("c69bff"), .position = 1.0 },
};

fn App() !void {
    forbear.component("app")({
        forbear.element(.{
            .width = .{ .grow = 1.0 },
            .direction = .vertical,
            .xJustification = .center,
            .yJustification = .start,
            .background = .{ .color = Colors.page },
            .font = try forbear.useFont("SpaceGrotesk"),
            .fontWeight = 400,
            .fontSize = 16.0,
            .color = Colors.text,
        })({
            forbear.FpsCounter();

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .background = .{ .gradient = &rainbowBar },
                .padding = .block(15.0),
                .xJustification = .center,
                .yJustification = .center,
                .fontWeight = 500,
            })({
                forbear.text("-> Book a 15 minute meeting today.");
            });

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .minHeight = 72.0,
                .padding = .inLine(15.0),
                .xJustification = .center,
                .yJustification = .center,
            })({
                forbear.image(.{
                    .width = .{ .fixed = 100.0 },
                    .margin = forbear.Margin.right(24.0),
                }, try forbear.useImage("uhoh-logo"));
                forbear.element(.{
                    .width = .{ .grow = 1.0 },
                    .background = .{ .color = .{ 1.0, 0.0, 0.0, 1.0 } },
                })({});
                forbear.element(.{
                    .fontWeight = 500,
                    .margin = .right(16.0),
                    .padding = .all(20.0),
                    .cursor = .pointer,
                })({
                    forbear.text("Pricing");
                });
                Button(.{})({
                    forbear.text("Try it risk-free");
                });
            });

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .margin = .block(36.0),
                .direction = .horizontal,
                .xJustification = .start,
                .yJustification = .center,
            })({
                forbear.element(.{
                    .direction = .vertical,
                    .width = .{ .grow = 1.0 },
                })({
                    forbear.element(.{
                        .fontWeight = 700,
                        .fontSize = 64,
                        .lineHeight = 0.9,
                        .margin = .bottom(24.0),
                    })({
                        forbear.text("You're the boss, why are you still fixing tech issues?");
                    });
                    forbear.element(.{
                        .fontSize = 20.0,
                        .margin = .bottom(25.0),
                    })({
                        forbear.text("It doesn't just annoy you. It slows you and your staff down. That's our job now.");
                    });
                    Button(.{})({
                        forbear.text("Let us prove it*");
                    });
                    forbear.element(.{
                        .fontSize = 12.0,
                        .lineHeight = 1.3,
                        .margin = .top(20.0),
                    })({
                        forbear.text(
                            "* You have to promise us that you'll dump all your problems on us so that we can show you what we're made of.",
                        );
                    });
                });
                forbear.image(.{
                    .width = .{ .grow = 1.0 },
                    .padding = .left(30.0),
                    .blendMode = .multiply,
                }, try forbear.useImage("uhoh-hero"));
            });

            const statements = [_][]const u8{
                "Less problems, more productivity",
                "Your team runs smoother",
                "A hundred things less on your plate",
            };

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = .block(30.0),
                .margin = .block(48.0),
                .borderWidth = .block(2.0),
                .borderColor = black,
            })({
                for (statements, 0..) |statement, i| {
                    forbear.element(.{
                        .direction = .horizontal,
                        .xJustification = .start,
                        .yJustification = .center,
                        .width = .{ .grow = 1.0 },
                        .padding = if (i > 0) .left(20.0) else null,
                    })({
                        forbear.image(.{
                            .width = .{ .fixed = 30.0 },
                            .height = .{ .fixed = 30.0 },
                            .blendMode = .multiply,
                            .margin = .right(15.0),
                        }, try forbear.useImage("uhoh-check"));
                        forbear.text(statement);
                    });
                }
            });

            const issues = [_][]const u8{
                "You got a cryptic error message on an app. Now you have to submit a ticket.",
                "Your Google ads literally just got disabled and you're not sure why. Now you have to submit a ticket.",
                "Someone on your team lost access to a shared account. Now you have to submit a ticket.",
            };

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(22.5).withBottom(30.0),
            })({
                forbear.image(.{
                    .width = .{ .grow = 1.0 },
                    .maxWidth = 369,
                    .blendMode = .multiply,
                    .margin = forbear.Margin.inLine(0.0).withRight(24.0),
                }, try forbear.useImage("uhoh-problem"));
                forbear.element(.{
                    .direction = .vertical,
                    .width = .{ .grow = 1.0 },
                })({
                    forbear.element(.{
                        .fontWeight = 600,
                        .fontSize = 10.5,
                        .color = Colors.muted,
                    })({
                        forbear.text("You're a growing business.");
                    });
                    forbear.element(.{
                        .fontWeight = 700,
                        .fontSize = 24.0,
                        .margin = forbear.Margin.block(4.5).withBottom(12.0),
                    })({
                        forbear.text("But your day-to-day has some of this BS in it:");
                    });

                    for (issues, 0..) |issue, i| {
                        forbear.element(.{
                            .direction = .horizontal,
                            .padding = .block(9.0),
                            .fontSize = 10.5,
                            .borderWidth = if (i == 0) null else .top(1.5),
                            .borderColor = black,
                        })({
                            forbear.image(.{
                                .width = .{ .fixed = 30.0 },
                                .height = .{ .fixed = 30.0 },
                                .blendMode = .multiply,
                                .margin = .right(7.5),
                            }, try forbear.useImage("uhoh-x-red"));
                            forbear.element(.{ .fontSize = 12.0 })({
                                forbear.text(issue);
                            });
                        });
                    }
                    forbear.element(.{
                        .fontSize = 12.0,
                        .margin = .bottom(30.0),
                    })({
                        forbear.text("Imagine if you could delegate all these issues to a genie?");
                    });
                    Button(.{})({
                        forbear.text("Get a free trial");
                    });
                });
            });

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
                        Testimonial("uhoh-testimonial-1")({
                            forbear.text("I'll be honest, we didn't know we needed help with the IT/Tech side of our business. After bringing on uhoh, I realized that I was very wrong. In the first month we built out systems and processes that will give us the capacity to scale well past where we were targeting for this year. Bonus is any time we have a problem and hit a wall, they just fix it. It really is like having a full IT team on standby. 10/10 recommend this.");

                            forbear.text("Clifton Sellers, Founder/CEO");
                            forbear.text("Legacy Builders");
                        });

                        Testimonial("uhoh-testimonial-2")({
                            forbear.text("uhoh is reliable and easy to work with. They solve complex problems quickly and bring forward smart, modern solutions that actually move the business forward. What sets them apart is how deeply they think about the company's vision, not just fixing tech issues but using technology to support growth, efficiency, and long-term impact.");

                            forbear.text("Na'eem Adam, Founder/CEO");
                            forbear.text("Parkour, Le Burger Week");
                        });

                        Testimonial("uhoh-testimonial-moses")({
                            forbear.text("I had an incredible experience with uhoh. They were fast, professional, and knowledgeable. I really appreciated their transparent flat-fee pricing, which made the whole process stress-free and affordable. They handled everything with ease and went above and beyond to make sure I was satisfied. Highly recommend to anyone looking for reliable systems support!");

                            forbear.text("Moses Lam, Owner");
                            forbear.text("Artisanal Mortgages");
                        });
                    });

                    forbear.element(.{
                        .width = .{ .grow = 1.0 },
                    })({
                        Testimonial("uhoh-testimonial-alex")({
                            forbear.text("One of the best decisions I've made as a founder. So much time saved to focus on everything else. I didn't even realize how much time I was losing previously. Highly recommend.");

                            forbear.text("Alex Stewart, Founder/CEO");
                            forbear.text("Teamtown");
                        });

                        Testimonial("uhoh-testimonial-stephanie")({
                            forbear.text("uhoh has been the solution I didn't know I needed. Deep and Erica are empathetic and care about the things I need in my business to be successful. They are working behind the scenes to help me scale without adding people. Thank you for your support!");

                            forbear.text("Stephanie O'Brien, President");
                            forbear.text("Carmella");
                        });

                        Testimonial("uhoh-testimonial-enoch")({
                            forbear.text("We've been using uhoh since they started and it's been a pleasure. Great attention to detail, super proactive and always delivering value.");

                            forbear.text("Enoch Taralson, Director of Revenue Operations");
                            forbear.text("Dingus & Zazzy");
                        });
                    });
                });
            });

            const logos = [_][]const u8{
                "uhoh-partner-badge",
                "uhoh-google-logo",
                "uhoh-microsoft-logo",
                "uhoh-partner-logo",
                "uhoh-zoho-logo",
            };

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .padding = .all(15.0),
                .borderWidth = .all(1.5),
                .borderColor = black,
                .borderRadius = 9.0,
                .direction = .vertical,
            })({
                forbear.element(.{
                    .fontWeight = 700,
                    .width = .{ .grow = 1.0 },
                    .xJustification = .center,
                    .yJustification = .center,
                    .fontSize = 18.0,
                    .margin = forbear.Margin.block(0.0).withBottom(13.5),
                })({
                    forbear.text("Our partners");
                });
                forbear.element(.{
                    .direction = .horizontal,
                    .xJustification = .center,
                    .yJustification = .center,
                })({
                    for (logos) |id| {
                        forbear.image(.{
                            .maxWidth = 128,
                            .maxHeight = 112,
                            .filter = .grayscale,
                            .margin = forbear.Margin.right(13.5),
                        }, try forbear.useImage(id));
                    }
                });
            });

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(22.5).withBottom(30.0),
                .direction = .vertical,
            })({
                forbear.image(.{
                    .width = .{ .grow = 1.0 },
                    .maxWidth = 600,
                    .blendMode = .multiply,
                }, try forbear.useImage("uhoh-solution"));
                forbear.element(.{
                    .fontWeight = 700,
                    .fontSize = 22.5,
                    .margin = forbear.Margin.block(13.5).withBottom(7.5),
                })({
                    forbear.text("We're here to reinvent how tech gets done.");
                });
                forbear.element(.{
                    .fontSize = 12.0,
                    .color = Colors.muted,
                    .xJustification = .center,
                    .yJustification = .start,
                })({
                    forbear.text("We're replacing clunky IT with clean, fast, and flexible support. Built for startups and teams that just want things to work.");
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

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(22.5).withBottom(37.5),
            })({
                forbear.element(.{ .direction = .vertical })({
                    inline for (offerings) |offering| {
                        forbear.element(.{
                            .width = .{ .grow = 1.0 },
                            .background = .{ .color = Colors.card },
                            .borderRadius = 12.0,
                            .borderColor = Colors.border,
                            .borderWidth = .all(0.75),
                            .padding = .all(15.0),
                            .margin = forbear.Margin.block(0.0).withBottom(12.0),
                            .direction = .vertical,
                        })({
                            forbear.element(.{
                                .direction = .horizontal,
                                .xJustification = .start,
                                .yJustification = .center,
                                .margin = forbear.Margin.block(0.0).withBottom(9.0),
                            })({
                                forbear.image(.{
                                    .width = .{ .grow = 1.0 },
                                    .maxWidth = 100.0,
                                    .blendMode = .multiply,
                                    .margin = forbear.Margin.right(9.0),
                                }, try forbear.useImage(offering.imageId));
                                forbear.element(.{
                                    .fontWeight = 700,
                                    .fontSize = 16.5,
                                })({
                                    forbear.text(offering.title);
                                });
                            });
                            inline for (offering.bullets) |bullet| {
                                forbear.element(.{
                                    .direction = .horizontal,
                                    .margin = forbear.Margin.block(0.0).withBottom(4.5),
                                })({
                                    forbear.element(.{
                                        .width = .{ .fixed = 6.0 },
                                        .height = .{ .fixed = 6.0 },
                                        .background = .{ .color = Colors.accentDark },
                                        .borderRadius = 3.0,
                                        .margin = forbear.Margin.inLine(0.0).withRight(7.5),
                                    })({});
                                    forbear.element(.{ .fontSize = 11.25 })({
                                        forbear.text(bullet);
                                    });
                                });
                            }
                            forbear.element(.{
                                .background = .{ .color = Colors.soft },
                                .borderRadius = 9.0,
                                .padding = .all(9.0),
                                .margin = forbear.Margin.block(10.5).withBottom(0.0),
                            })({
                                forbear.element(.{
                                    .fontWeight = 600,
                                    .fontSize = 12.0,
                                    .margin = forbear.Margin.block(0.0).withBottom(4.5),
                                })({
                                    forbear.text(offering.addonTitle);
                                });
                                forbear.element(.{
                                    .fontSize = 10.5,
                                    .color = Colors.muted,
                                })({
                                    forbear.text(offering.addonBody);
                                });
                            });
                        });
                    }
                });
            });

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(15.0).withBottom(30.0),
            })({
                forbear.element(.{
                    .direction = .horizontal,
                })({
                    forbear.image(.{
                        .width = .{ .fixed = 150.0 },
                        .height = .{ .fixed = 150.0 },
                        .margin = forbear.Margin.inLine(0.0).withRight(12.0),
                    }, try forbear.useImage("uhoh-jon-avatar"));
                    forbear.element(.{
                        .direction = .vertical,
                    })({
                        forbear.element(.{
                            .fontSize = 13.5,
                            .lineHeight = 1.4,
                        })({
                            forbear.text("I literally built this because I needed it for myself... it has to be fast, incredibly good and insanely affordable. It's usually impossible to get all three, but we figured it out and we're willing to go to great lengths to let you experience that for yourself.");
                        });
                        forbear.element(.{
                            .fontSize = 10.5,
                            .color = Colors.muted,
                            .margin = forbear.Margin.block(9.0).withBottom(0.0),
                        })({
                            forbear.text("- Jon Sturgeon, CEO of Dingus & Zazzy & Co-Founder of uhoh");
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

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(22.5).withBottom(30.0),
            })({
                forbear.element(.{
                    .direction = .horizontal,
                    .xJustification = .start,
                    .yJustification = .center,
                })({
                    forbear.element(.{
                        .width = .{ .fixed = 390.0 },
                        .direction = .vertical,
                    })({
                        forbear.element(.{
                            .fontWeight = 700,
                            .fontSize = 22.5,
                            .margin = forbear.Margin.block(0.0).withBottom(10.5),
                        })({
                            forbear.text("Your tech works. People are happy. Time comes back.");
                        });
                        inline for (benefits) |benefit| {
                            forbear.element(.{
                                .direction = .horizontal,
                                .margin = forbear.Margin.block(0.0).withBottom(6.0),
                                .xJustification = .start,
                                .yJustification = .center,
                            })({
                                forbear.element(.{
                                    .width = .{ .fixed = 6.0 },
                                    .height = .{ .fixed = 6.0 },
                                    .background = .{ .color = Colors.accentDark },
                                    .borderRadius = 3.0,
                                    .margin = forbear.Margin.inLine(0.0).withRight(7.5),
                                })({});
                                forbear.element(.{ .fontSize = 12.0 })({
                                    forbear.text(benefit);
                                });
                            });
                        }
                    });
                    forbear.image(.{
                        .width = .{ .grow = 1.0 },
                        .maxWidth = 169,
                        .blendMode = .multiply,
                        .margin = forbear.Margin.left(24.0),
                    }, try forbear.useImage("uhoh-group-21"));
                });
                forbear.element(.{
                    .direction = .horizontal,
                    .xJustification = .start,
                    .yJustification = .center,
                    .margin = forbear.Margin.block(13.5).withBottom(0.0),
                })({
                    forbear.image(.{
                        .width = .{ .grow = 1.0 },
                        .maxWidth = 169,
                        .blendMode = .multiply,
                        .margin = forbear.Margin.inLine(0.0).withRight(10.5),
                    }, try forbear.useImage("uhoh-failure"));
                    forbear.element(.{
                        .fontSize = 12.0,
                        .color = Colors.muted,
                    })({
                        forbear.text("Or... keep asking your most tech-savvy employee to fix the WiFi. You could save money, time, and headaches - or keep duct-taping your IT together until it breaks.");
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

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(22.5).withBottom(30.0),
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
                            .background = .{ .color = Colors.card },
                            .borderRadius = 9.0,
                            .borderColor = Colors.border,
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
                                .color = Colors.muted,
                            })({
                                forbear.text(faq.answer);
                            });
                        });
                    }
                    // TODO: interactive accordion behaviour for FAQ items when event-driven toggles per element are available.
                });
            });

            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(22.5).withBottom(37.5),
            })({
                forbear.element(.{
                    .direction = .vertical,
                    .xJustification = .center,
                    .yJustification = .start,
                })({
                    forbear.image(.{
                        .height = .{ .fixed = 200.0 },
                        .blendMode = .multiply,
                    }, try forbear.useImage("uhoh-bottom-cta"));
                    forbear.element(.{
                        .fontWeight = 700,
                        .fontSize = 22.5,
                        .margin = forbear.Margin.block(13.5).withBottom(7.5),
                    })({
                        forbear.text("Dude, you're at the bottom of our landing page.");
                    });
                    forbear.element(.{
                        .fontSize = 12.0,
                        .color = Colors.muted,
                        .margin = forbear.Margin.block(0.0).withBottom(20.0),
                    })({
                        forbear.text("Just get the free trial already if you're that interested. You scrolled all the way here.");
                    });

                    Button(.{})({
                        forbear.text("Come on, click on this");
                        forbear.element(.{
                            .fontSize = 14.0,
                        })({
                            forbear.text("Don't make me beg");
                        });
                    });
                });
            });
            forbear.element(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .background = .{ .color = Colors.soft },
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.top(15.0).withBottom(19.5),
            })({
                forbear.element(.{
                    .direction = .vertical,
                })({
                    forbear.element(.{
                        .direction = .horizontal,
                        .xJustification = .center,
                        .yJustification = .center,
                    })({
                        forbear.image(.{
                            .width = .{ .fixed = 90.0 },
                            .margin = forbear.Margin.right(9.0),
                        }, try forbear.useImage("uhoh-logo"));
                        forbear.element(.{ .fontSize = 9.0 })({
                            forbear.text("Privacy Policy");
                        });
                    });
                    forbear.element(.{
                        .direction = .horizontal,
                        .margin = forbear.Margin.block(12.0).withBottom(0.0),
                    })({
                        forbear.element(.{
                            .fontSize = 9.0,
                            .color = Colors.muted,
                            .margin = forbear.Margin.inLine(0.0).withRight(15.0),
                        })({
                            forbear.text("© 2025 uhoh. All rights reserved.");
                        });
                        forbear.element(.{
                            .fontSize = 9.0,
                            .color = Colors.muted,
                        })({
                            forbear.text("Designed by your lover, Loogart");
                        });
                    });
                });
            });
        });
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    io: std.Io,
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

    var traceFile = try std.Io.Dir.cwd().createFile(io, "layouting.log", .{});
    defer traceFile.close(io);
    var traceBuffer: [4096]u8 = undefined;
    var traceWriter = traceFile.writer(io, &traceBuffer);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.frame(.{
            .arena = arena,
            .viewportSize = renderer.viewportSize(),
            .baseStyle = .{
                .font = try forbear.useFont("SpaceGrotesk"),
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .textWrapping = .word,
                .fontWeight = 400,
                .cursor = .default,
                .lineHeight = 1.0,
                .blendMode = .normal,
            },
        })({
            // I want this to include more than one element if it's the case I'm defining it like this
            try App();

            const rootTree = try forbear.layout();
            try rootTree.dump(&traceWriter.interface);

            try renderer.drawFrame(arena, rootTree, .{ 0.99, 0.98, 0.96, 1.0 }, window.targetFrameTimeNs());
            try forbear.update();
        });
    }
    try renderer.waitIdle();
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
    };
    defer if (is_debug) {
        if (debug_allocator.deinit() == .leak) {
            std.log.err("Memory was leaked", .{});
        }
    };

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

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

    try forbear.init(allocator, io, &renderer);
    defer forbear.deinit();

    forbear.setWindowHandlers(window);

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            io,
            &renderer,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
