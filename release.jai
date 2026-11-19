#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "Process";
#import "String";

#run release();
release :: () {
    set_build_options_dc(.{do_output = false});

    #if OS == .WINDOWS {
        platform    :: "win32";
        compiler    :: "jai";
        static_lib  :: "lib";
        c_libraries :: string.["forbear.dll", "forbear.lib"];
    } else #if OS == .LINUX {
        platform    :: "linux";
        compiler    :: "jai-linux";
        static_lib  :: "a";
        c_libraries :: string.["forbear.so"];
    } else #if OS == .MACOS {
        platform    :: "darwin";
        compiler    :: "jai-macos";
        static_lib  :: "a";
        c_libraries :: string.["forbear.dylib"];
    }

    root  := #filepath;

    revision, commit := run_command("git", "rev-parse", "HEAD", working_directory = root, capture_and_return_output = true);
    assert(revision.type == .EXITED && revision.exit_code == 0, "git rev-parse HEAD failed");
    commit = trim(commit);
    tag   := slice(commit, 0, 7);
    _, changes := run_command("git", "status", "--porcelain", working_directory = root, capture_and_return_output = true);
    assert(changes == "", "The release is named after commit %, but these changes are not in it. Commit or stash them first:\n%", tag, changes);

    src   := join(root, "modules/forbear/");
    stage := join(root, ".build/release/");
    if is_directory(stage) delete_directory(stage);

    run(join(src, "c-api"), compiler, "build.jai");

    jai := tprint("%forbear-jai-%/", stage, platform);
    copy(join(src, "module.jai"), join(jai, "module.jai"));
    for string.["bindings-darwin.jai", "bindings-linux.jai", "bindings-win32.jai",
                tprint("vendor/freetype-%.%", platform, static_lib),
                tprint("vendor/kb_text_shape-%.%", platform, static_lib)] {
        copy(join(src, it), join(jai, it));
    }
    copy(join(root, "LICENSE"), join(jai, "LICENSE"));

    c := tprint("%forbear-c-%/", stage, platform);
    for c_libraries copy(tprint("%c-api/%", src, it), join(c, it));
    copy(join(src, "c-api/forbear.h"), join(c, "forbear.h"));
    copy(join(root, "LICENSE"), join(c, "LICENSE"));

    exists := run_command("gh", "release", "view", tag, working_directory = root).exit_code == 0;
    if !exists {
        run(root,
            "gh",
            "release",
            "create", tag,
            "--target", commit,
            "--title", tag,
            "--latest");
    }

    upload_command_arguments: [..]string;
    array_add(*upload_command_arguments, "gh", "release", "upload", tag, "--clobber");
    for string.[jai, c] {
        directory := slice(it, 0, it.count - 1);
        archive   := join(directory, ".tar.gz");
        run(stage, "tar", "-czf", archive, "-C", directory, ".");
        array_add(*upload_command_arguments, archive);
    }
    run(root, ..upload_command_arguments);
}

copy :: (from: string, to: string) {
    assert(file_exists(from), "% is missing. Run `jai generate.jai` in modules/forbear first.", from);
    make_directory_if_it_does_not_exist(path_strip_filename(to), recursive = true);
    assert(copy_file(from, to), "could not copy % to %", from, to);
}

run :: (working_directory: string, command: .. string) {
    result := run_command(..command, working_directory = working_directory);
    assert(result.type == .EXITED && result.exit_code == 0, "% failed", join(..command, " "));
}
