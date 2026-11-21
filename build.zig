const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const t = target.result;

    const upstream = b.dependency("upstream", .{});

    const config_h = b.addConfigHeader(.{ .style = .blank }, .{
        .PACKAGE = "faac",
        .PACKAGE_VERSION = "2.2.0",
        .HAVE_GETOPT_H = true,
        .HAVE_IMMINTRIN_H = true,
        .WORDS_BIGENDIAN = if (t.cpu.arch.endian() == .big) true else null,
        .HAVE_SSE2 = if (t.cpu.arch.isX86()) true else null,
        .FAAC_SBR_DECIMATION = 1,
        .FAAC_STATS = null,
        .MAX_CHANNELS = 8,
    });

    const faac = b.addLibrary(.{
        .name = "faac",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .dynamic,
        .version = .{ .major = 2, .minor = 0, .patch = 0 },
    });
    faac.root_module.addConfigHeader(config_h);
    faac.root_module.addCSourceFiles(.{
        .root = upstream.path("libfaac"),
        .files = &common_src,
        .flags = &.{
            "-includeconfig.h",
            "-DCOMMON_PREFIX=faac_",
            "-fvisibility=hidden",
        },
    });
    if (t.cpu.arch.isX86()) {
        faac.root_module.addCSourceFile(.{
            .file = upstream.path("libfaac/quantize_sse.c"),
            .flags = &.{
                "-includeconfig.h",
                "-DCOMMON_PREFIX=faac_",
                "-fvisibility=hidden",
            },
        });
    }
    faac.root_module.addIncludePath(upstream.path("include"));
    faac.installHeadersDirectory(upstream.path("include"), "", .{});
    b.installArtifact(faac);
}

const common_src = [_][]const u8{
    "bitstream.c",
    "blockswitch.c",
    "channels.c",
    "cpu_compute.c",
    "faac.c",
    "filtbank.c",
    "fft.c",
    "frame.c",
    "huff2.c",
    "huffdata.c",
    "quantize.c",
    "ratecontrol.c",

    "sbr.c",
    "sbr_bitstream.c",
    "sbr_tables.c",
    "sbr_analysis.c",
    "resample.c",

    "stereo.c",
    "tns.c",
    "util.c",
};
