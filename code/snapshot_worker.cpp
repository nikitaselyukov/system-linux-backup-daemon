#include <chrono>
#include <filesystem>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <ctime>

namespace fs = std::filesystem;
using sys_clock = std::chrono::system_clock;

static void check_paths(fs::path& source, fs::path& target) {
    if (!fs::exists(source)) {
        throw std::runtime_error("source does not exist: " + source.string());
    }
    if (!fs::is_directory(source)) {
        throw std::runtime_error("source is not a directory: " + source.string());
    }

    source = fs::canonical(source);

    if (!fs::exists(target)) {
        fs::create_directories(target);
        std::cout << "created target directory: " << target << '\n';
    }
    if (!fs::is_directory(target)) {
        throw std::runtime_error("target is not a directory: " + target.string());
    }

    target = fs::canonical(target);
}

static std::string make_timestamp() {
    const std::time_t now = sys_clock::to_time_t(sys_clock::now());
    std::tm local_tm{};
    localtime_r(&now, &local_tm);

    std::ostringstream out;
    out << std::put_time(&local_tm, "%Y-%m-%d_%H-%M-%S");
    return out.str();
}

static void run_backup(const fs::path& source, const fs::path& target) {
    const fs::path backup_dir = target / make_timestamp();
    fs::create_directories(backup_dir);

    for (const auto& entry : fs::directory_iterator(source)) {
        fs::copy(
            entry.path(),
            backup_dir / entry.path().filename(),
            fs::copy_options::recursive
        );
    }

    std::cout << "backup completed: " << source << " -> " << backup_dir << '\n';
}

int main(int argc, char** argv) {
    try {
        if (argc != 3) {
            throw std::runtime_error("usage: snapshot_worker <source> <target>");
        }

        fs::path source = argv[1];
        fs::path target = argv[2];

        check_paths(source, target);
        run_backup(source, target);
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "snapshot_worker: " << ex.what() << '\n';
        return 1;
    }
}
