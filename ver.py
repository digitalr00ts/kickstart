import json
from typing import Dict

from fedfind.release import get_release


def gen_vars(release: str = "Rawhide") -> Dict[str, str]:
    rtn = dict()
    rel = get_release(release=release)
    rtn["version"] = rel.release

    if release.casefold() != "rawhide":
        rtn["release"] = rel.label.split("-")[-1]
        raise RuntimeError("Not Implemented")

    rtn["release"] = rel.compose + ".n.0"

    return rtn


def main():
    # TODO: Get stable release
    print(json.dumps(gen_vars(), sort_keys=True, indent=4))


if __name__ == "__main__":
    main()
