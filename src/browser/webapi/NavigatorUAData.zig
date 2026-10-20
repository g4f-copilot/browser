// Copyright (C) 2023-2026  Lightpanda (Selecy SAS)
//
// Francis Bouvier <francis@lightpanda.io>
// Pierre Tachoire <pierre@lightpanda.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const Config = @import("../../Config.zig");
const js = @import("../js/js.zig");
const Execution = js.Execution;

const NavigatorUAData = @This();

_pad: bool = false,

const Brand = struct {
    brand: []const u8,
    version: []const u8,
};

fn getBrands(_: *const NavigatorUAData) []const Brand {
    return brandList();
}

fn getMobile(_: *const NavigatorUAData) bool {
    return false;
}

fn getPlatform(_: *const NavigatorUAData) []const u8 {
    return uaPlatform();
}

pub fn toJSON(_: *const NavigatorUAData) struct {
    brands: []const Brand,
    mobile: bool,
    platform: []const u8,
} {
    return .{
        .mobile = false,
        .brands = brandList(),
        .platform = uaPlatform(),
    };
}

fn getHighEntropyValues(_: *const NavigatorUAData, hints: []const []const u8, exec: *const Execution) !js.Promise {
    // This should always return `brands` + `mobile` + `platform` and then whatever
    // "hints" field is requested (assuming the browser has permission), but it's
    // also valid to just return everything.

    _ = hints;

    const brands = brandList();

    return exec.js.local.?.resolvePromise(.{
        .brands = brandList(),
        .mobile = false,
        .platform = uaPlatform(),
        .architecture = uaArchitecture(),
        .bitness = uaBitness(),
        .model = "",
        .platformVersion = "",
        .uaFullVersion = if (brands.len > 0) brands[0].version else "1.0.0.0",
        .fullVersionList = brands,
        .wow64 = false,
        .formFactor = [_][]const u8{"Desktop"},
    });
}

fn brandList() []const Brand {
    const out = comptime blk: {
        const src = &Config.HttpHeaders.brands;
        var arr: [src.len]Brand = undefined;
        for (src, 0..) |b, i| {
            arr[i] = .{ .brand = b.brand, .version = b.full_version };
        }
        const final = arr;
        break :blk final;
    };
    return &out;
}

fn uaPlatform() []const u8 {
    // Matches the Windows User-Agent and Sec-Ch-Ua-Platform defaults.
    return "Windows";
}

fn uaArchitecture() []const u8 {
    // Matches the "Win64; x64" User-Agent default.
    return "x86";
}

fn uaBitness() []const u8 {
    // Matches the "Win64; x64" User-Agent default.
    return "64";
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(NavigatorUAData);

    pub const Meta = struct {
        pub const name = "NavigatorUAData";
        pub var class_id: bridge.ClassId = undefined;
        pub const empty_with_no_proto = true;
    };

    pub const brands = bridge.accessor(NavigatorUAData.getBrands, null, .{});
    pub const mobile = bridge.accessor(NavigatorUAData.getMobile, null, .{});
    pub const platform = bridge.accessor(NavigatorUAData.getPlatform, null, .{});
    pub const toJSON = bridge.function(NavigatorUAData.toJSON, .{});
    pub const getHighEntropyValues = bridge.function(NavigatorUAData.getHighEntropyValues, .{});
};
