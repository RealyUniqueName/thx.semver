package thx.semver;

using StringTools;

abstract Version(SemVer) from SemVer to SemVer {
  static var VERSION = ~/^(\d+)\.(\d+)\.(\d+)(?:[-]([a-z0-9.-]+))?(?:[+]([a-z0-9.-]+))?$/i;
  @:from public static function stringToVersion(s : String) {
    if(!VERSION.match(s)) throw 'Invalid SemVer format for "$s"';
    var major = Std.parseInt(VERSION.matched(1)),
        minor = Std.parseInt(VERSION.matched(2)),
        patch = Std.parseInt(VERSION.matched(3)),
        pre   = parseIdentifiers(VERSION.matched(4)),
        build = parseIdentifiers(VERSION.matched(5));
    return new Version(major, minor, patch, pre, build);
  }

  public inline function new(major = 0, minor = 0, patch = 0, pre : Array<Identifier>, build : Array<Identifier>)
    this = {
      version : [major, minor, patch],
      pre : pre,
      build : build
    };

  public var major(get, never) : Int;
  public var minor(get, never) : Int;
  public var patch(get, never) : Int;
  public var pre(get, never) : String;
  public var build(get, never) : String;

  @:to public function toString() {
    var v = this.version.join('.');
    if(this.pre.length > 0)
      v += '-$pre';
    if(this.build.length > 0)
      v += '+$build';
    return v;
  }

  @:op(A==B) public function equals(other : Version) {
    if(major != other.major || minor != other.minor || patch != other.patch)
      return false;
    return equalsIdentifiers(this.pre, (other : SemVer).pre);
  }

  @:op(A!=B) public function different(other : Version)
    return !(other.equals(this));

  @:op(A>B) public function greaterThan(other : Version) {
    if(major != other.major)
      return major > other.major;
    if(minor != other.minor)
      return minor > other.minor;
    if(patch != other.patch)
      return patch > other.patch;
    if(this.pre.length == 0 && (other : SemVer).pre.length > 0)
      return true;
    return greaterThanIdentifiers(this.pre, (other : SemVer).pre);
  }

  @:op(A>=B) public function greaterThanOrEqual(other : Version) {
    return equals(other) || greaterThan(other);
  }

  @:op(A<B) public function lesserThan(other : Version) {
    return !greaterThanOrEqual(other);
  }

  @:op(A<=B) public function lesserThanOrEqual(other : Version) {
    return !greaterThan(other);
  }

  inline function get_major() return this.version[0];
  inline function get_minor() return this.version[1];
  inline function get_patch() return this.version[2];

  inline function get_pre() return identifiersToString(this.pre);
  inline function get_build() return identifiersToString(this.build);

  static function identifiersToString(ids : Array<Identifier>)
    return ids.map(function(id) return switch id {
        case StringId(s): s;
        case IntId(i): '$i';
      }).join('.');

  static function parseIdentifiers(s : String) : Array<Identifier>
    return (null == s ? '' : s).split('.')
      .map(sanitize)
      .filter(function(s) return s != '')
      .map(parseIdentifier);

  static function parseIdentifier(s : String) : Identifier {
    var i = Std.parseInt(s);
    return null == i ? StringId(s) : IntId(i);
  }

  static function equalsIdentifiers(a : Array<Identifier>, b : Array<Identifier>) {
    if(a.length != b.length)
      return false;
    for(i in 0...a.length)
      switch [a[i], b[i]] {
        case [StringId(a), StringId(b)] if(a != b): return false;
        case [IntId(a), IntId(b)] if(a != b): return false;
        case _:
      }
    return true;
  }

  static function greaterThanIdentifiers(a : Array<Identifier>, b : Array<Identifier>) {
    for(i in 0...a.length)
      switch [a[i], b[i]] {
        case [StringId(a), StringId(b)] if(a == b): continue;
        case [IntId(a), IntId(b)] if(a == b): continue;
        case [StringId(a), StringId(b)] if(a > b): return true;
        case [IntId(a), IntId(b)] if(a > b): return true;
        case [StringId(_), IntId(_)]: return true;
        case _: return false;
      }
    return false;
  }

  static var SANITIZER = ~/[^0-9A-Za-z-]/g;
  static function sanitize(s : String) : String
    return SANITIZER.replace(s, '');
}

enum Identifier {
  StringId(value : String);
  IntId(value : Int);
}

typedef SemVer = {
  version : Array<Int>,
  pre : Array<Identifier>,
  build : Array<Identifier>
}