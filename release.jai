#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Process";
#import "String";

RELEASE_TAG :: "snapshot";

#run release();
release :: () {
    set_build_options_dc(.{do_output = false});

    #if OS == .WINDOWS {
        platform    :: "win32";
        static_lib  :: "lib";
        c_libraries :: string.["forbear.dll", "forbear.lib"];
    } else #if OS == .LINUX {
        platform    :: "linux";
        static_lib  :: "a";
        c_libraries :: string.["forbear.so"];
    } else #if OS == .MACOS {
        platform    :: "darwin";
        static_lib  :: "a";
        c_libraries :: string.["forbear.dylib"];
    }

    root  := #filepath;
    src   := join(root, "%src/");
    stage := join(root, "%.build/release/");
    if is_directory(stage) delete_directory(stage);

    run(join(src, "c-api"), "jai", "build.jai");

    jai := tprint("%forbear-jai-%/", stage, platform);
    copy(join(src, "forbear.jai"), join(jai, "module.jai"));
    for string.["bindings-darwin.jai", "bindings-linux.jai", "bindings-win32.jai",
                tprint("vendor/freetype-%.%", platform, static_lib),
                tprint("vendor/kb_text_shape-%.%", platform, static_lib)] {
        copy(join(src, it), join(jai, it));
    }
    copy(join(root, "LICENSE"), join(root, "LICENSE"));

    c := tprint("%forbear-c-%/", stage, platform);
    for c_libraries copy(tprint("%c-api/%", src, it), join(c, it));
    copy(join(src, "c-api/forbear.h"), join(c, "forbear.h"));
    copy(join(root, "LICENSE"), join(c, "LICENSE"));

    archives: [..]string;
    for string.[jai, c] {
        directory := slice(it, 0, it.count - 1);
        archive   := join(directory, "%.tar.gz");
        run(stage, "tar", "-czf", archive, "-C", directory, ".");
        array_add(*archives, archive);
    }

    exists := run_command("gh", "release", "view", RELEASE_TAG, working_directory = root).exit_code == 0;
    if !exists run(root,
                   "gh",
                   "release",
                   "create", RELEASE_TAG,
                   "--title", RELEASE_TAG,
                   "--notes", "Prebuilt forbear files that the quick start downloads.");
    run(root, "gh", "release", "upload", RELEASE_TAG, "--clobber", ..archives);
}

copy :: (from: string, to: string) {
    assert(file_exists(from), "% is missing. Run `jai generate.jai` in src first.", from);
    make_directory_if_it_does_not_exist(path_strip_filename(to), recursive = true);
    assert(copy_file(from, to), "could not copy % to %", from, to);
}

run :: (working_directory: string, command: .. string) {
    result := run_command(..command, working_directory = working_directory);
    assert(result.type == .EXITED && result.exit_code == 0, "% failed", join(..command, " "));
}
