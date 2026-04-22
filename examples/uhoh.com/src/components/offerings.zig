const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

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

pub fn Offerings() !void {
    Section(.{
        .yJustification = .start,
        .padding = forbear.Padding.top(22.5).withBottom(37.5),
    })({
        forbear.element(.{ .direction = .vertical })({
            inline for (offerings) |offering| {
                forbear.element(.{
                    .width = .{ .grow = 1.0 },
                    .borderRadius = 12.0,
                    .borderColor = colors.black,
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
                                .borderRadius = 3.0,
                                .margin = forbear.Margin.inLine(0.0).withRight(7.5),
                            })({});
                            forbear.element(.{ .fontSize = 11.25 })({
                                forbear.text(bullet);
                            });
                        });
                    }
                    forbear.element(.{
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
                        })({
                            forbear.text(offering.addonBody);
                        });
                    });
                });
            }
        });
    });
}
