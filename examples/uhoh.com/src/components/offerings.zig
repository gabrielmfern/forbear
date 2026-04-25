const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;
const List = @import("list.zig").List;
const ListItem = @import("list.zig").ListItem;

pub const OfferingProps = struct {
    title: []const u8,
    imageId: []const u8,
    addonTitle: []const u8,
    addonBody: []const u8,

    style: forbear.Style = .{},
};

pub fn Offering(props: OfferingProps) *const fn (void) void {
    forbear.component(.{})({
        forbear.element(.{ .style = props.style.overwrite(.{
            .width = .{ .grow = 1.0 },
            .height = .{ .grow = 1.0 },
            .borderRadius = 12.0,
            .borderColor = colors.black,
            .borderWidth = .all(2.0),
            .padding = .all(20.0),
            .margin = forbear.Margin.block(0.0).withBottom(12.0),
            .direction = .vertical,
        }) })({
            forbear.element(.{ .style = .{
                .direction = .horizontal,
                .xJustification = .start,
                .yJustification = .center,
                .margin = forbear.Margin.block(0.0).withBottom(9.0),
            } })({
                forbear.Image(.{
                    .width = .{ .fixed = 100.0 },
                    .blendMode = .multiply,
                    .margin = forbear.Margin.right(9.0),
                }, forbear.useImage(props.imageId) catch unreachable);
                forbear.element(.{ .style = .{
                    .fontWeight = 700,
                    .fontSize = 16.5,
                } })({
                    forbear.text(props.title);
                });
            });
            forbear.componentChildrenSlot();
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
            } })({});
            forbear.element(.{ .style = .{
                .borderRadius = 12.0,
                .borderWidth = .all(2.0),
                .borderColor = colors.black,
                .borderStyle = .dashed,
                .fontSize = 12.0,
                .direction = .vertical,
                .padding = forbear.Padding.block(10.0).withInLine(20.0),
            } })({
                forbear.element(.{ .style = .{
                    .fontSize = 18.0,
                    .margin = .block(10.0),
                } })({
                    forbear.text(props.addonTitle);
                });
                forbear.text(props.addonBody);
            });
        });
    });
    return forbear.componentChildrenSlotEnd();
}

pub fn Offerings() !void {
    Section(.{
        .maxWidth = 1269.0,
        .xJustification = .center,
    })({
        forbear.element(.{ .style = .{
            .direction = .vertical,
            .width = .{ .grow = 1.0 },
        } })({
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .margin = .bottom(20.0),
            } })({
                Offering(.{
                    .title = "Basic IT & Tech Support",
                    .imageId = "uhoh-offer-46",
                    .addonTitle = "+ Expanded IT & Tech Support",
                    .addonBody = "Assisting an in house team with: Device provisioning & procurement (laptops, phones, accessories) • Mobile Device Management (MDM) setup (e.g. Jamf, Intune) • Printer & peripheral configuration • Network diagnostics & optimization (e.g., Wi-Fi mapping, router config) • Remote desktop troubleshooting (e.g., AnyDesk, TeamViewer deployment) • BYOD policy setup & support • Business continuity planning / backup systems (Dropbox, Backblaze, Google Vault)",
                    .style = .{
                        .margin = forbear.Margin.right(20.0).withBottom(12.0),
                    },
                })({
                    List()({
                        ListItem()({
                            forbear.text("Basic IT");
                        });
                        ListItem()({
                            forbear.text("Work space administration (Google & Microsoft)");
                        });
                        ListItem()({
                            forbear.text("User setup");
                        });
                        ListItem()({
                            forbear.text("User termination");
                        });
                        ListItem()({
                            forbear.text("VPN set up");
                        });
                        ListItem()({
                            forbear.text("Password Management & 2FA");
                        });
                        ListItem()({
                            forbear.text("Misfired Automations");
                        });
                        ListItem()({
                            forbear.text("Hardware problems");
                        });
                        ListItem()({
                            forbear.text("Software issues (Any tool not working correctly)");
                        });
                        ListItem()({
                            forbear.text("Access problems");
                        });
                        ListItem()({
                            forbear.text("Video meeting problems");
                        });
                        ListItem()({
                            forbear.text("User access");
                        });
                    });
                });
                Offering(.{
                    .title = "Website & Domain",
                    .imageId = "uhoh-offer-47",
                    .addonTitle = "+ Expanded Web and Domain Support",
                    .addonBody = "DNS diagnostics & hardening • Speed optimization audits (Core Web Vitals, GTmetrix, etc.) • Accessibility & compliance testing (WCAG/ADA tools) • CDN configuration (e.g., Cloudflare setup) • Firewall or DDoS protection setup (Cloudflare, Sucuri) • Uptime alerts routed to Slack/Email",
                })({
                    List()({
                        ListItem()({
                            forbear.text("Website");
                        });
                        ListItem()({
                            forbear.text("Domain connection");
                        });
                        ListItem()({
                            forbear.text("Domain purchases");
                        });
                        ListItem()({
                            forbear.text("Domain monitoring");
                        });
                        ListItem()({
                            forbear.text("SSL Certifications");
                        });
                        ListItem()({
                            forbear.text("Website form integrations");
                        });
                        ListItem()({
                            forbear.text("Payment integrations");
                        });
                        ListItem()({
                            forbear.text("Website monitoring");
                        });
                        ListItem()({
                            forbear.text("Hosting reviews");
                        });
                        ListItem()({
                            forbear.text("Access problems");
                        });
                        ListItem()({
                            forbear.text("Video meeting problems");
                        });
                        ListItem()({
                            forbear.text("User access");
                        });
                    });
                });
            });
            forbear.element(.{ .style = .{
                .width = .{ .grow = 1.0 },
                .margin = .bottom(20.0),
            } })({
                Offering(.{
                    .title = "SaaS Spending, Tool Audits & Finance Ops",
                    .imageId = "uhoh-offer-50",
                    .addonTitle = "+ Expanded Finance / SaaS",
                    .addonBody = "Subscription lifecycle management • Shadow IT detection • SaaS access control by role / department • Expense policy enforcement workflows",
                    .style = .{
                        .margin = forbear.Margin.right(20.0).withBottom(12.0),
                    },
                })({
                    List()({
                        ListItem()({
                            forbear.text("Saas Spending/Tool Audits/Software research ");
                        });
                        ListItem()({
                            forbear.text("Spend Audits");
                        });
                        ListItem()({
                            forbear.text("Tool Review");
                        });
                        ListItem()({
                            forbear.text("Consolidation");
                        });
                        ListItem()({
                            forbear.text("Price negotiation");
                        });
                        ListItem()({
                            forbear.text("Activity logs & reporting");
                        });
                        ListItem()({
                            forbear.text("Float (online spending)");
                        });
                    });
                });
                Offering(.{
                    .title = "Security Audits & Controls",
                    .imageId = "uhoh-offer-49",
                    .addonTitle = "+ Expanded Team Training",
                    .addonBody = "Device encryption setup (FileVault, BitLocker) • Compliance readiness consulting (SOC2-lite, ISO-lite for startups) • Zero Trust access implementation (per device/user/location rules) • Internal vulnerability testing / pen test coordination",
                })({
                    List()({
                        ListItem()({
                            forbear.text("Security Audits");
                        });
                        ListItem()({
                            forbear.text("MFA (workspace & individual users)");
                        });
                        ListItem()({
                            forbear.text("Password share tool (zoho, lastpass, Nordpass, Onepassword)");
                        });
                        ListItem()({
                            forbear.text("SSO");
                        });
                        ListItem()({
                            forbear.text("Team Training (InfoSec, Knowbe4)");
                        });
                        ListItem()({
                            forbear.text("Phishing training");
                        });
                    });
                });
            });
        });
    });
}
