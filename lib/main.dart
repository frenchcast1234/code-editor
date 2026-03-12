import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'JetBrains Mono',
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Color(0xff888888)),
          trackColor: WidgetStateProperty.all(Color(0xff333333)),
          trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      home: CodeField(),
    );
  }
}

class CodeField extends StatefulWidget {
  const CodeField({super.key});

  @override
  State<CodeField> createState() => _CodeFieldState();
}

enum thm { clair, sombre }

class _CodeFieldState extends State<CodeField> {
  // MethodChannel pour "toujours au premier plan" (desktop natif, sans plugin tiers)
  static const _windowChannel = MethodChannel('app.editor/window');

  // Controllers
  final _searchController = TextEditingController();
  final _replaceController = TextEditingController();
  final TextEditingController _consoleController = TextEditingController();
  final FocusNode _consoleFocusNode = FocusNode();

  // Recherche
  String _searchQuery = '';
  int _searchCurrentMatch = 0;
  List<int> _searchMatches = [];
  bool _showReplace = false;

  // Settings
  double fontSize = 14;
  double lineHeight = 1.4;
  String mode = "basic";
  double spacesPerTab = 4;

  // Real settings
  final _fontSizeController = TextEditingController(text: "14");
  bool convertTabsToSpace = false;
  final _tabsSizeController = TextEditingController(text: "4");
  bool encapsulerLesLignes = true;
  bool showLineNumbers = true;
  bool retraitIntelligent = true;
  bool toujoursAuPremierPlan = false;
  thm thmSelected = thm.sombre;

  // Tabs system
  List<String?> filePaths = [null, null];
  List<String> fileNames = ["Text", "Txt2"];
  List<bool> fileModified = [false, false]; // true = non sauvegardé

  // Undo/Redo par onglet
  List<List<TextEditingValue>> _undoStacks = [[], []];
  List<List<TextEditingValue>> _redoStacks = [[], []];
  static const int _maxHistorySize = 200;
  bool _isUndoRedo = false;
  List<SyntaxController> controllers = [
    SyntaxController(
      text: r""" 
// TypeScript avancé : Manipulation de types et génériques complexes
type DeepReadonly<T> = T extends object ? { readonly [K in keyof T]: DeepReadonly<T[K]> } : T;

interface ApiResponse<T> {
    status: number;
    data: T;
    meta: { timestamp: string; requestId: string };
}

type ExtractNestedData<T, K extends keyof T> = T[K] extends Array<infer U> ? U : T[K];

const fetchData = async <T extends object, K extends keyof T>(url: string, key: K): Promise<ExtractNestedData<T, K>[]> => {
    try { 
        const response: ApiResponse<T> = await (await fetch(url)).json(); 
        if (response.status !== 200) throw new Error(`Fetch failed with status ${response.status} for requestId ${response.meta.requestId} at ${response.meta.timestamp}`);
        return (response.data[key] as unknown) as ExtractNestedData<T, K>[];
    } catch (err) {
        console.error(`Error fetching data from ${url}: ${(err as Error).message}`, err); 
        return [];
    }
};

type ComplexData = { users: { id: string; profile: { name: string; age: number; tags: string[]; addresses: { city: string; country: string; zip: string }[] }[] } };

(async () => {
    const users: DeepReadonly<ComplexData["users"]> = await fetchData<ComplexData, "users">("https://api.example.com/users", "users");
    const namesAndCities: string[] = users.flatMap(user => user.profile.flatMap(p => p.addresses.map(a => `${p.name} lives in ${a.city}, ${a.country} (${a.zip})`)));
    console.log(namesAndCities.join(" | "));
})();
      """,
      thmSelected: thm.sombre,
      baseStyle: TextStyle(
        color: Color(0xffebebeb),
        fontSize: 14,
        height: 1.4,
        fontFamily: 'JetBrains Mono',
      ),
    ),
    SyntaxController(
      text: r"""
/* =========================================================
   Advanced Utility Types
   ========================================================= */

type Primitive = string | number | boolean | bigint | symbol | null | undefined;

type DeepReadonly<T> =
  T extends Primitive
    ? T
    : T extends Array<infer U>
      ? ReadonlyArray<DeepReadonly<U>>
      : { readonly [K in keyof T]: DeepReadonly<T[K]> };

type Nullable<T> = T | null;

type Optional<T> = {
  [K in keyof T]?: T[K];
};

type Mutable<T> = {
  -readonly [K in keyof T]: T[K];
};

type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
};

type ValueOf<T> = T[keyof T];

type ExtractNestedData<T, K extends keyof T> =
  T[K] extends Array<infer U> ? U : T[K];

type AsyncReturnType<T extends (...args: any) => Promise<any>> =
  T extends (...args: any) => Promise<infer R> ? R : never;


/* =========================================================
   API Types
   ========================================================= */

interface ApiMeta {
  timestamp: string;
  requestId: string;
  duration?: number;
}

interface ApiResponse<T> {
  status: number;
  data: T;
  meta: ApiMeta;
}

interface ApiError {
  message: string;
  code: number;
  details?: unknown;
}


/* =========================================================
   Domain Types
   ========================================================= */

type Address = {
  city: string;
  country: string;
  zip: string;
};

type Profile = {
  name: string;
  age: number;
  tags: string[];
  addresses: Address[];
};

type User = {
  id: string;
  profile: Profile[];
};

type ComplexData = {
  users: User[];
};


/* =========================================================
   Logger
   ========================================================= */

namespace Logger {

  export type LogLevel =
    | "debug"
    | "info"
    | "warn"
    | "error";

  export interface LogEntry {
    level: LogLevel;
    message: string;
    timestamp: string;
    context?: Record<string, unknown>;
  }

  export class ConsoleLogger {

    private history: LogEntry[] = [];

    log(level: LogLevel, message: string, context?: Record<string, unknown>) {

      const entry: LogEntry = {
        level,
        message,
        timestamp: new Date().toISOString(),
        context
      };

      this.history.push(entry);

      switch (level) {
        case "debug":
          console.debug(message, context);
          break;
        case "info":
          console.info(message, context);
          break;
        case "warn":
          console.warn(message, context);
          break;
        case "error":
          console.error(message, context);
          break;
      }
    }

    getHistory(): ReadonlyArray<LogEntry> {
      return this.history;
    }
  }
}

const logger = new Logger.ConsoleLogger();


/* =========================================================
   API Client
   ========================================================= */

class ApiClient {

  constructor(private baseUrl: string) {}

  async request<T>(path: string): Promise<ApiResponse<T>> {

    const start = performance.now();

    try {

      const response = await fetch(`${this.baseUrl}${path}`);

      const json = await response.json();

      const end = performance.now();

      return {
        ...json,
        meta: {
          ...json.meta,
          duration: end - start
        }
      };

    } catch (err) {

      logger.log(
        "error",
        "API request failed",
        { path, err }
      );

      throw err;
    }
  }
}


/* =========================================================
   Fetch Helper
   ========================================================= */

const fetchData = async <
  T extends object,
  K extends keyof T
>(
  url: string,
  key: K
): Promise<ExtractNestedData<T, K>[]> => {

  try {

    const response: ApiResponse<T> =
      await (await fetch(url)).json();

    if (response.status !== 200) {

      throw new Error(
        `Fetch failed with status ${response.status} ` +
        `for requestId ${response.meta.requestId} ` +
        `at ${response.meta.timestamp}`
      );
    }

    return (response.data[key] as unknown)
      as ExtractNestedData<T, K>[];

  } catch (err) {

    console.error(
      `Error fetching data from ${url}:`,
      (err as Error).message,
      err
    );

    return [];
  }
};


/* =========================================================
   Data Utilities
   ========================================================= */

function groupBy<T, K extends keyof any>(
  array: T[],
  getKey: (item: T) => K
): Record<K, T[]> {

  return array.reduce((acc, item) => {

    const key = getKey(item);

    if (!acc[key]) {
      acc[key] = [];
    }

    acc[key].push(item);

    return acc;

  }, {} as Record<K, T[]>);
}


function unique<T>(array: T[]): T[] {
  return [...new Set(array)];
}


/* =========================================================
   Mock API (for testing)
   ========================================================= */

const mockApiData: ComplexData = {
  users: Array.from({ length: 10 }).map((_, i) => ({
    id: `user-${i}`,
    profile: [
      {
        name: `User ${i}`,
        age: 20 + i,
        tags: ["typescript", "developer", "user"],
        addresses: [
          {
            city: "Paris",
            country: "France",
            zip: "75000"
          },
          {
            city: "Berlin",
            country: "Germany",
            zip: "10115"
          }
        ]
      }
    ]
  }))
};


/* =========================================================
   Data Processing Pipeline
   ========================================================= */

async function processUsers() {

  const users: DeepReadonly<ComplexData["users"]> =
    await fetchData<ComplexData, "users">(
      "https://api.example.com/users",
      "users"
    );

  const namesAndCities: string[] =
    users.flatMap(user =>
      user.profile.flatMap(profile =>
        profile.addresses.map(addr =>
          `${profile.name} lives in ${addr.city}, ${addr.country} (${addr.zip})`
        )
      )
    );

  const groupedByCountry =
    groupBy(namesAndCities, str =>
      str.split(",")[1].trim()
    );

  logger.log("info", "Users processed", {
    count: users.length
  });

  console.log(namesAndCities.join(" | "));

  return groupedByCountry;
}


/* =========================================================
   Execution
   ========================================================= */

(async () => {

  try {

    const result = await processUsers();

    console.log("Grouped Result:", result);

  } catch (err) {

    logger.log("error", "Fatal error", {
      error: err
    });

  }

})();
      """,
      thmSelected: thm.sombre,
      baseStyle: TextStyle(
        color: Color(0xffebebeb),
        fontSize: 14,
        height: 1.4,
        fontFamily: 'JetBrains Mono',
      ),
    ),
  ];
  List<FocusNode> focusNodes = [FocusNode(), FocusNode()];
  List<ScrollController> scrollTxtControllers = [ScrollController(), ScrollController()];
  List<ScrollController> scrollNumControllers = [ScrollController(), ScrollController()];
  List<ScrollController> scrollTxtHControllers = [ScrollController(), ScrollController()];
  List<ScrollController> scrollHBarControllers = [ScrollController(), ScrollController()];
  List<double> maxLineWidths = [0.0, 0.0];
  int currentIndex = 0;

  // Console
  List<List<String>> consoleOutput = [];

  Timer? _searchDebounceTimer;

  // ---------- helpers pour ajouter un onglet ----------
  void _addTab({String? name, String? path, String content = ''}) {
    final tabName = name ?? 'Nouveau fichier ${fileNames.length + 1}';
    fileNames.add(tabName);
    filePaths.add(path);
    fileModified.add(false);
    _undoStacks.add([]);
    _redoStacks.add([]);
    controllers.add(SyntaxController(
      text: content,
      thmSelected: thmSelected,
      baseStyle: TextStyle(
        color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
        fontSize: fontSize,
        height: lineHeight,
        fontFamily: 'JetBrains Mono',
      ),
    ));
    focusNodes.add(FocusNode());
    scrollTxtControllers.add(ScrollController());
    scrollNumControllers.add(ScrollController());
    scrollTxtHControllers.add(ScrollController());
    scrollHBarControllers.add(ScrollController());
    maxLineWidths.add(0.0);
    final k = controllers.length - 1;
    scrollTxtControllers[k].addListener(() {
      if (scrollNumControllers[k].hasClients) {
        scrollNumControllers[k].jumpTo(scrollTxtControllers[k].offset);
      }
    });
    scrollTxtHControllers[k].addListener(() {
      if (scrollHBarControllers[k].hasClients &&
          scrollHBarControllers[k].offset != scrollTxtHControllers[k].offset) {
        scrollHBarControllers[k].jumpTo(scrollTxtHControllers[k].offset);
      }
    });
    scrollHBarControllers[k].addListener(() {
      if (scrollTxtHControllers[k].hasClients &&
          scrollTxtHControllers[k].offset != scrollHBarControllers[k].offset) {
        scrollTxtHControllers[k].jumpTo(scrollHBarControllers[k].offset);
      }
    });
    controllers[k].addListener(() {
      if (_searchQuery.isNotEmpty && k == currentIndex) {
        _searchDebounceTimer?.cancel();
        _searchDebounceTimer = Timer(Duration(milliseconds: 300), () {
          _updateSearch(_searchQuery);
        });
      }
    });
  }

  // ---------- enregistrer ----------
  Future<void> _saveFile(int idx) async {
    if (filePaths[idx] != null) {
      await File(filePaths[idx]!).writeAsString(controllers[idx].text);
      setState(() => fileModified[idx] = false);
    } else {
      await _saveFileAs(idx);
    }
  }

  Future<void> _saveFileAs(int idx) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer sous',
      fileName: fileNames[idx].replaceAll('*', '').trim(),
      allowedExtensions: ['txt', 'ts', 'js', 'dart', 'py', 'json', 'md', 'html', 'css', 'xml', 'yaml', 'yml', 'lua', 'rb', 'go', 'rs', 'cpp', 'c', 'h', 'java', 'kt', 'swift'],
      type: FileType.custom,
    );
    if (savePath != null) {
      await File(savePath).writeAsString(controllers[idx].text);
      final newName = savePath.split(Platform.pathSeparator).last;
      setState(() {
        filePaths[idx] = savePath;
        fileNames[idx] = newName;
        fileModified[idx] = false;
      });
    }
  }

  // ---------- recherche ----------
  void _updateSearch(String query) {
    _searchQuery = query;
    _searchMatches = [];
    _searchCurrentMatch = 0;

    if (query.isEmpty) {
      controllers[currentIndex].searchMatches = [];
      controllers[currentIndex].searchMatchLen = 0;
      controllers[currentIndex].currentMatchIndex = -1;
    } else {
      final text = controllers[currentIndex].text;
      int start = 0;
      while (true) {
        final idx = text.indexOf(query, start);
        if (idx == -1) break;
        _searchMatches.add(idx);
        start = idx + query.length;
      }
      controllers[currentIndex].searchMatches = List.from(_searchMatches);
      controllers[currentIndex].searchMatchLen = query.length;
      controllers[currentIndex].currentMatchIndex = _searchMatches.isNotEmpty ? 0 : -1;
    }

    controllers[currentIndex].notifyListeners(); // remplace forceRebuildSpans()
    if (mounted) setState(() {});
  }

  void _searchNext() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _searchCurrentMatch = (_searchCurrentMatch + 1) % _searchMatches.length;
      controllers[currentIndex].currentMatchIndex = _searchCurrentMatch;
    });
    _jumpToMatch(_searchCurrentMatch);
  }

  void _searchPrev() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _searchCurrentMatch = (_searchCurrentMatch - 1 + _searchMatches.length) % _searchMatches.length;
      controllers[currentIndex].currentMatchIndex = _searchCurrentMatch;
    });
    _jumpToMatch(_searchCurrentMatch);
  }

  void _jumpToMatch(int matchIdx) {
    final pos = _searchMatches[matchIdx];
    controllers[currentIndex].selection = TextSelection(
      baseOffset: pos,
      extentOffset: pos + _searchQuery.length,
    );
    _scrollToPosition(pos);
  }

  void _scrollToPosition(int charPos) {
    final sc = scrollTxtControllers[currentIndex];
    if (!sc.hasClients) return;

    final text = controllers[currentIndex].text;
    final textBefore = text.substring(0, charPos.clamp(0, text.length));
    final linesBefore = '\n'.allMatches(textBefore).length;

    final painter = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          fontFamily: 'JetBrains Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lineH = painter.preferredLineHeight;

    final targetY = linesBefore * lineH;
    final viewportH = sc.position.viewportDimension;
    final scrollTo = (targetY - viewportH / 2).clamp(
      sc.position.minScrollExtent,
      sc.position.maxScrollExtent,
    );

    sc.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _replaceCurrent() {
    if (_searchMatches.isEmpty || _searchQuery.isEmpty) return;
    final ctrl = controllers[currentIndex];
    final pos = _searchMatches[_searchCurrentMatch];
    final replaceWith = _replaceController.text;
    final newText = ctrl.text.replaceRange(pos, pos + _searchQuery.length, replaceWith);
    ctrl.value = ctrl.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + replaceWith.length),
    );
    _updateSearch(_searchQuery);
    if (_searchMatches.isNotEmpty) {
      _searchCurrentMatch = _searchCurrentMatch.clamp(0, _searchMatches.length - 1);
      _jumpToMatch(_searchCurrentMatch);
    }
    setState(() {});
  }

  void _replaceAll() {
    if (_searchQuery.isEmpty) return;
    final ctrl = controllers[currentIndex];
    final replaceWith = _replaceController.text;
    final newText = ctrl.text.replaceAll(_searchQuery, replaceWith);
    ctrl.value = ctrl.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: 0),
    );
    _updateSearch(_searchQuery);
    setState(() {});
  }

  // ---------- undo / redo ----------
  void _undo(int idx) {
    final stack = _undoStacks[idx];
    if (stack.isEmpty) return;
    // Sauvegarder l'état courant dans redo AVANT de changer
    _redoStacks[idx].add(controllers[idx].value);
    _isUndoRedo = true;
    controllers[idx].value = stack.removeLast();
    _isUndoRedo = false;
    setState(() {});
  }

  void _redo(int idx) {
    final stack = _redoStacks[idx];
    if (stack.isEmpty) return;
    // Sauvegarder l'état courant dans undo AVANT de changer
    _undoStacks[idx].add(controllers[idx].value);
    _isUndoRedo = true;
    controllers[idx].value = stack.removeLast();
    _isUndoRedo = false;
    setState(() {});
  }

  bool get _canUndo => _undoStacks[currentIndex].isNotEmpty;
  bool get _canRedo => _redoStacks[currentIndex].isNotEmpty;

  // ---------- insérer une tabulation ----------
  void _insertTab(int idx) {
    final controller = controllers[idx];
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;
    final tabSize = spacesPerTab.toInt();
    if (selection.isCollapsed) {
      final cursor = selection.start.clamp(0, text.length);
      final lineStartRaw = text.lastIndexOf('\n', cursor - 1);
      final lineStart = lineStartRaw == -1 ? 0 : lineStartRaw + 1;
      final column = cursor - lineStart;
      final spacesToInsert = tabSize - (column % tabSize);
      controller.value = controller.value.copyWith(
        text: text.replaceRange(cursor, cursor, ' ' * spacesToInsert),
        selection: TextSelection.collapsed(offset: cursor + spacesToInsert),
      );
    } else {
      // Indenter la sélection
      final start = selection.start;
      final end = selection.end;
      final spaces = ' ' * tabSize;
      final newText = text.replaceRange(start, end, spaces);
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start + spaces.length),
      );
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    for (int k = 0; k < controllers.length; k++) {
      scrollTxtControllers[k].addListener(() {
        if (scrollNumControllers[k].hasClients) {
          scrollNumControllers[k].jumpTo(scrollTxtControllers[k].offset);
        }
      });scrollTxtHControllers[k].addListener(() {
        if (scrollHBarControllers[k].hasClients &&
            scrollHBarControllers[k].offset != scrollTxtHControllers[k].offset) {
          scrollHBarControllers[k].jumpTo(scrollTxtHControllers[k].offset);
        }
      });
      scrollHBarControllers[k].addListener(() {
        if (scrollTxtHControllers[k].hasClients &&
            scrollTxtHControllers[k].offset != scrollHBarControllers[k].offset) {
          scrollTxtHControllers[k].jumpTo(scrollHBarControllers[k].offset);
        }
      });
    }
    for (int k = 0; k < controllers.length; k++) {
      final idx = k;
      TextEditingValue _prevValue = controllers[k].value;
      controllers[k].addListener(() {
        if (_isUndoRedo) {
          _prevValue = controllers[idx].value;
          return;
        }
        if (!fileModified[idx]) {
          setState(() => fileModified[idx] = true);
        }
        final current = controllers[idx].value;
        if (current.text != _prevValue.text) {
          final stack = _undoStacks[idx];
          if (stack.isEmpty || stack.last.text != _prevValue.text) {
            stack.add(_prevValue);
            if (stack.length > _maxHistorySize) stack.removeAt(0);
          }_redoStacks[idx].clear();

          if (_searchQuery.isNotEmpty && idx == currentIndex) {
            _searchDebounceTimer?.cancel();
            _searchDebounceTimer = Timer(Duration(milliseconds: 300), () {
              _updateSearch(_searchQuery);
            });
          }
        }
        _prevValue = current;
      });
    }
    _searchController.addListener(() {
      _updateSearch(_searchController.text);
    });
  }

  double _computeMaxLineWidth(int index) {
    final style = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: 'JetBrains Mono',
    );
    double maxW = 0;
    for (final line in controllers[index].text.split('\n')) {
      final tp = TextPainter(
        text: TextSpan(text: line, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxW) maxW = tp.width;
    }
    return maxW;
  }

  String _tabLabel(int i) {
    final base = fileNames[i];
    return fileModified[i] ? '● $base' : base;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: controllers.length,
      child: Scaffold(
        backgroundColor: thmSelected == thm.sombre
            ? Color(0xff1f1f1f)
            : Colors.white,
        appBar: AppBar(
          backgroundColor: thmSelected == thm.sombre
              ? Color(0xff1f1f1f)
              : Colors.white,
          flexibleSpace:
              MediaQuery.of(context).orientation == Orientation.landscape
              ? Stack(
                  children: [
                    Center(
                      child: Text(
                        'Text',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: thmSelected == thm.sombre
                              ? Color(0xffebebeb)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          iconTheme: IconThemeData(
            color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
          ),
          toolbarHeight: 48.0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(2),
            child: Container(
              color: thmSelected == thm.sombre
                  ? Color(0x1fffffff)
                  : Color(0x0a000000),
              height: 2.0,
            ),
          ),
          leadingWidth: 280.0,
          leading: Row(
            children: [
              SizedBox(width: 8.0),
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: thmSelected == thm.sombre
                          ? Color(0xffebebeb)
                          : Colors.black,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
              if (MediaQuery.of(context).orientation == Orientation.landscape) ...[
                SizedBox(width: 24.0),
                Container(
                  height: 30,
                  width: 208,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: thmSelected == thm.sombre
                          ? Color(0x1fffffff)
                          : Color(0x0a000000),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: thmSelected == thm.sombre
                                ? Color(0xffebebeb)
                                : Colors.black,
                            fontSize: 14,
                            height: 1.0,
                          ),
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Rechercher...',
                            hintStyle: TextStyle(
                              color: thmSelected == thm.sombre
                                  ? Color(0x55ffffff)
                                  : Color(0x55000000),
                              fontSize: 14,
                            ),
                            contentPadding: EdgeInsets.only(left: 12.0),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _searchNext(),
                        ),
                      ),
                      if (_searchMatches.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${_searchCurrentMatch + 1}/${_searchMatches.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: thmSelected == thm.sombre
                                  ? Color(0x99ffffff)
                                  : Color(0x99000000),
                            ),
                          ),
                        ),
                      if (_searchQuery.isNotEmpty)
                        InkWell(
                          onTap: _searchPrev,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.keyboard_arrow_up, size: 18,
                                color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                          ),
                        ),
                      if (_searchQuery.isNotEmpty)
                        InkWell(
                          onTap: _searchNext,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.keyboard_arrow_down, size: 18,
                                color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (MediaQuery.of(context).orientation == Orientation.landscape && _searchQuery.isNotEmpty) ...[
              Tooltip(
                message: _showReplace ? 'Masquer le remplacement' : 'Afficher le remplacement',
                child: IconButton(
                  icon: Icon(_showReplace ? Icons.find_replace : Icons.find_replace_outlined),
                  color: _showReplace
                      ? const Color(0xff1b72e8)
                      : (thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                  onPressed: () => setState(() => _showReplace = !_showReplace),
                ),
              ),
              if (_showReplace) ...[
                SizedBox(
                  width: 150,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      ),
                    ),
                    child: TextField(
                      controller: _replaceController,
                      style: TextStyle(
                        color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                        fontSize: 13,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Remplacer...',
                        hintStyle: TextStyle(
                          color: thmSelected == thm.sombre ? Color(0x55ffffff) : Color(0x55000000),
                          fontSize: 13,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _replaceCurrent(),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Remplacer',
                  child: IconButton(
                    icon: Icon(Icons.find_replace, size: 20),
                    color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                    onPressed: _replaceCurrent,
                  ),
                ),
                Tooltip(
                  message: 'Tout remplacer',
                  child: IconButton(
                    icon: Icon(Icons.sync_alt, size: 20),
                    color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                    onPressed: _replaceAll,
                  ),
                ),
              ],
            ],
            IconButton(
              onPressed: _canUndo ? () => _undo(currentIndex) : null,
              icon: Icon(Icons.arrow_back),
              color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
              disabledColor: thmSelected == thm.sombre ? Color(0x33ffffff) : Color(0x33000000),
              tooltip: 'Annuler',
            ),
            IconButton(
              onPressed: _canRedo ? () => _redo(currentIndex) : null,
              icon: Icon(Icons.arrow_forward),
              color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
              disabledColor: thmSelected == thm.sombre ? Color(0x33ffffff) : Color(0x33000000),
              tooltip: 'Rétablir',
            ),
            IconButton(
              onPressed: () => _insertTab(currentIndex),
              icon: Icon(Icons.keyboard_tab),
              color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
              tooltip: 'Tabulation',
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: thmSelected == thm.sombre
              ? Color(0xff1f1f1f)
              : Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (mode == "basic") ...[
                // ----- En-tête -----
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(bottom: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  height: 50.0,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text('Text',
                      style: TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold,
                        color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                // ----- Fichiers -----
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(bottom: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _drawerButton('Nouveau fichier', () {
                          setState(() {
                            _addTab();
                            currentIndex = fileNames.length - 1;
                          });
                        }),
                        SizedBox(height: 8.0),
                        _drawerButton('Ouvrir', () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['txt', 'ts', 'js', 'dart', 'py', 'json', 'md', 'html', 'css', 'xml', 'yaml', 'yml', 'lua', 'rb', 'go', 'rs', 'cpp', 'c', 'h', 'java', 'kt', 'swift'],
                            allowMultiple: false,
                          );
                          if (result != null && result.files.single.path != null) {
                            final path = result.files.single.path!;
                            final name = result.files.single.name;
                            final content = await File(path).readAsString();
                            setState(() {
                              _addTab(name: name, path: path, content: content);
                              fileModified[fileNames.length - 1] = false;
                              currentIndex = fileNames.length - 1;
                            });
                          }
                        }),
                        SizedBox(height: 8.0),
                        _drawerButton('Enregistrer', () async {
                          await _saveFile(currentIndex);
                        }),
                        SizedBox(height: 8.0),
                        _drawerButton('Enregistrer sous', () async {
                          await _saveFileAs(currentIndex);
                        }),
                      ],
                    ),
                  ),
                ),
                // ----- Barre de recherche portrait -----
                if (MediaQuery.of(context).orientation == Orientation.portrait) ...[
                  // Bloc Rechercher
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                      border: Border(bottom: BorderSide(
                        color: Colors.transparent, // I don't wanna rewrite this section just for removing one border
                        width: 2.0,
                      )),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
                          child: Text('Rechercher',
                            style: TextStyle(fontSize: 13, letterSpacing: 0.8,
                              color: thmSelected == thm.sombre ? Color(0x99ffffff) : Color(0x99000000)),
                          ),
                        ),
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black, fontSize: 14, height: 1.0),
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Rechercher...',
                                    hintStyle: TextStyle(color: thmSelected == thm.sombre ? Color(0x55ffffff) : Color(0x55000000), fontSize: 14, height: 1.0),
                                    contentPadding: EdgeInsets.only(left: 16.0),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _searchNext(),
                                ),
                              ),
                              if (_searchMatches.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text('${_searchCurrentMatch + 1}/${_searchMatches.length}',
                                    style: TextStyle(fontSize: 11,
                                      color: thmSelected == thm.sombre ? Color(0x99ffffff) : Color(0x99000000))),
                                ),
                              if (_searchQuery.isNotEmpty) ...[
                                InkWell(onTap: _searchPrev,
                                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.keyboard_arrow_up, size: 20,
                                      color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black))),
                                InkWell(onTap: _searchNext,
                                  child: Padding(padding: const EdgeInsets.only(left: 2, right: 8),
                                    child: Icon(Icons.keyboard_arrow_down, size: 20,
                                      color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black))),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bloc Remplacer
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                      border: Border(bottom: BorderSide(
                        color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                        width: 2.0,
                      )),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
                          child: Text('Remplacer',
                            style: TextStyle(fontSize: 13, letterSpacing: 0.8,
                              color: thmSelected == thm.sombre ? Color(0x99ffffff) : Color(0x99000000)),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _replaceController,
                                        style: TextStyle(
                                          color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                                          fontSize: 14,
                                          height: 1.0
                                        ),
                                        textAlignVertical: TextAlignVertical.top,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Remplacer...',
                                          hintStyle: TextStyle(
                                            color: thmSelected == thm.sombre ? Color(0x55ffffff) : Color(0x55000000),
                                            fontSize: 14,
                                            height: 1.0
                                          ),
                                          contentPadding: EdgeInsets.only(left: 16.0),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (_) => _replaceCurrent(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Tooltip(
                              message: 'Remplacer',
                              child: InkWell(
                                onTap: _replaceCurrent,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.find_replace, size: 22,
                                    color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Tout remplacer',
                              child: InkWell(
                                onTap: _replaceAll,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.sync_alt, size: 22,
                                    color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                // ----- Navigation -----
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _drawerButton('Console', () => setState(() => mode = "console")),
                        SizedBox(height: 8.0),
                        _drawerButton('Exécuter', () {}),
                        SizedBox(height: 8.0),
                        _drawerButton('Crédits', () => setState(() => mode = "credits")),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(top: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: _drawerButton('Paramètres', () {
                        mode = "settings";
                        setState(() {});
                      }),
                    ),
                  ),
                ),
              ] else if (mode == "settings") ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(bottom: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  height: 50.0,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text('Paramètres',
                      style: TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold,
                        color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30.0, right: 8.0, top: 24.0, bottom: 24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _settingRow('Taille de la police', child:
                            SizedBox(
                              height: 36.0, width: 55.0,
                              child: TextField(
                                style: TextStyle(fontSize: 14,
                                    color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                                controller: _fontSizeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                ),
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                onSubmitted: (_) {
                                  final parsed = double.tryParse(_fontSizeController.text);
                                  setState(() {
                                    fontSize = (parsed ?? 14).clamp(8.0, 40.0).toDouble();
                                    _fontSizeController.text = fontSize.toInt().toString();
                                    for (var c in controllers) {
                                      c.baseStyle = c.baseStyle.copyWith(fontSize: fontSize, height: lineHeight);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          _settingRow('Convertir les tabulations en espaces', child:
                            _switch(convertTabsToSpace, (v) => setState(() => convertTabsToSpace = v)),
                          ),
                          _settingRow('Taille des tabulations', child:
                            SizedBox(
                              height: 36.0, width: 55.0,
                              child: TextField(
                                style: TextStyle(fontSize: 14,
                                    color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                                controller: _tabsSizeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                ),
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                onSubmitted: (_) {
                                  final parsed = double.tryParse(_tabsSizeController.text);
                                  setState(() {
                                    spacesPerTab = (parsed ?? 4).clamp(1.0, 10.0).toDouble();
                                    _tabsSizeController.text = spacesPerTab.toInt().toString();
                                  });
                                },
                              ),
                            ),
                          ),
                          _settingRow('Encapsuler les lignes', child:
                            _switch(encapsulerLesLignes, (v) => setState(() => encapsulerLesLignes = v)),
                          ),
                          _settingRow('Afficher les numéros de ligne', child:
                            _switch(showLineNumbers, (v) => setState(() => showLineNumbers = v)),
                          ),
                          _settingRow('Retrait intelligent', child:
                            _switch(retraitIntelligent, (v) => setState(() => retraitIntelligent = v)),
                          ),
                          _settingRow('Toujours au premier plan', child:
                            _switch(toujoursAuPremierPlan, (v) async {
                              setState(() => toujoursAuPremierPlan = v);
                              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                                try {
                                  await _windowChannel.invokeMethod('setAlwaysOnTop', {'value': v});
                                } catch (_) {}
                              }
                            }),
                          ),
                          SizedBox(height: 16.0),
                          SizedBox(
                            height: 36.0,
                            width: double.infinity,
                            child: Text('THÈME',
                              style: TextStyle(fontSize: 16,
                                  color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          _radioRow('Clair', thm.clair),
                          _radioRow('Sombre', thm.sombre),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(top: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: SizedBox(width: double.infinity,
                        child: _drawerButton('Retour', () { mode = "basic"; setState(() {}); })),
                  ),
                ),
              ] else if (mode == "console") ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(bottom: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  height: 50.0,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text('Console',
                      style: TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold,
                        color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
                          child: ListView(
                            children: List.generate(
                              consoleOutput.length,
                              (index) => Text(
                                '[${consoleOutput[index][0]}] ${consoleOutput[index][1]}',
                                style: TextStyle(
                                  color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                                  fontSize: 14,
                                  height: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                          border: Border(top: BorderSide(
                            color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                            width: 2.0,
                          )),
                        ),
                        width: double.infinity,
                        height: 36.0,
                        child: TextField(
                          controller: _consoleController,
                          focusNode: _consoleFocusNode,
                          autofocus: true,
                          style: TextStyle(
                            color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                            fontSize: 14,
                            height: 1.8,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Entrez une commande...',
                            hintStyle: TextStyle(
                              color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                            isDense: true,
                          ),
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          onSubmitted: (val) {
                            if (val.trim().isEmpty) {
                              _consoleFocusNode.requestFocus();
                              return;
                            }
                            setState(() {
                              consoleOutput.add([
                                DateTime.now().toIso8601String().substring(11, 19),
                                val.trim(),
                              ]);
                              _consoleController.clear();
                            });
                            _consoleFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(top: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: SizedBox(width: double.infinity,
                        child: _drawerButton('Retour', () { mode = "basic"; setState(() {}); })),
                  ),
                ),
              ] else if (mode == "credits") ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(bottom: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  height: 50.0,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text('Crédits',
                      style: TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold,
                        color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Le code de ce jeu est open-source et sera disponible sur GitHub.',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono', fontSize: 18,
                            color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Tout ce logiciel a été fait par frenchcast1234.',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono', fontSize: 18,
                            color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                    border: Border(top: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    )),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: SizedBox(width: double.infinity,
                        child: _drawerButton('Retour', () { mode = "basic"; setState(() {}); })),
                  ),
                ),
              ],
            ],
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: double.infinity,
              height: 32.0,
              child: TabBar(
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                    _updateSearch(_searchController.text);
                  });
                },
                isScrollable: true,
                labelPadding: EdgeInsets.symmetric(horizontal: 4.0),
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: "JetBrains Mono",
                  fontWeight: FontWeight.bold,
                ),
                labelColor: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                unselectedLabelStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: "JetBrains Mono",
                  fontWeight: FontWeight.normal,
                ),
                unselectedLabelColor: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                dividerColor: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                dividerHeight: 2.0,
                indicator: BoxDecoration(
                  color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                  border: Border(
                    bottom: BorderSide(
                      color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                      width: 2.0,
                    ),
                  ),
                ),
                indicatorColor: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                tabs: [
                  for (int i = 0; i < fileNames.length; i++)
                    Tab(child: Text(_tabLabel(i))),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (int i = 0; i < controllers.length; i++)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const lineNumbersWidth = 50.0;
                        const gapWidth = 8.0;
                        final textWidth =
                            constraints.maxWidth - lineNumbersWidth - gapWidth;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (encapsulerLesLignes) ...[
                              if (showLineNumbers) ...[
                                SizedBox(
                                  width: lineNumbersWidth,
                                  child: ScrollbarTheme(
                                    data: const ScrollbarThemeData(
                                      thumbVisibility: WidgetStatePropertyAll(false),
                                      trackVisibility: WidgetStatePropertyAll(false),
                                      thickness: WidgetStatePropertyAll(0),
                                    ),
                                    child: SingleChildScrollView(
                                      controller: scrollNumControllers[i],
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: LineNumbers(
                                        text: controllers[i].text,
                                        fontSize: fontSize,
                                        lineHeight: lineHeight,
                                        availableWidth: textWidth,
                                        wrap: true,
                                        thmSelected: thmSelected,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: gapWidth),
                              ],
                            ],
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Focus(
                                  focusNode: focusNodes[i],
                                  onKeyEvent: (node, event) {
                                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                                    final controller = controllers[i];
                                    final text = controller.text;
                                    final selection = controller.selection;
                                    final tabSize = spacesPerTab.toInt();
                                    final ctrl = HardwareKeyboard.instance.isControlPressed ||
                                        HardwareKeyboard.instance.isMetaPressed;

                                    // Ctrl+Z → undo
                                    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ &&
                                        !HardwareKeyboard.instance.isShiftPressed) {
                                      _undo(i);
                                      return KeyEventResult.handled;
                                    }

                                    // Ctrl+Y ou Ctrl+Shift+Z → redo
                                    if (ctrl && (event.logicalKey == LogicalKeyboardKey.keyY ||
                                        (event.logicalKey == LogicalKeyboardKey.keyZ &&
                                            HardwareKeyboard.instance.isShiftPressed))) {
                                      _redo(i);
                                      return KeyEventResult.handled;
                                    }

                                    if (selection.isCollapsed) {
                                      final cursor = selection.start.clamp(0, text.length);

                                      final lineStartRaw = text.lastIndexOf('\n', cursor - 1);
                                      final lineStart = lineStartRaw == -1 ? 0 : lineStartRaw + 1;
                                      final column = cursor - lineStart;

                                      // Tab → espaces
                                      if (event.logicalKey == LogicalKeyboardKey.tab) {
                                        final spacesToInsert = tabSize - (column % tabSize);
                                        controller.value = controller.value.copyWith(
                                          text: text.replaceRange(cursor, cursor, ' ' * spacesToInsert),
                                          selection: TextSelection.collapsed(offset: cursor + spacesToInsert),
                                        );
                                        return KeyEventResult.handled;
                                      }

                                      // Backspace intelligent (retrait intelligent)
                                      if (retraitIntelligent &&
                                          event.logicalKey == LogicalKeyboardKey.backspace &&
                                          cursor > 0) {
                                        int spaceCount = 0;
                                        for (int j = cursor - 1;
                                            j >= lineStart && text[j] == ' ';
                                            j--) {
                                          spaceCount++;
                                        }
                                        if (spaceCount > 1) {
                                          final removed = spaceCount % tabSize == 0
                                              ? tabSize
                                              : spaceCount % tabSize;
                                          final newStart = cursor - removed;
                                          controller.value = controller.value.copyWith(
                                            text: text.replaceRange(newStart, cursor, ''),
                                            selection: TextSelection.collapsed(offset: newStart),
                                          );
                                          return KeyEventResult.handled;
                                        }
                                      }
                                    }

                                    return KeyEventResult.ignored;
                                  },
                                  child: encapsulerLesLignes
                                      ? Scrollbar(
                                          controller: scrollTxtControllers[i],
                                          thumbVisibility: true,
                                          thickness: 8.0,
                                          radius: Radius.circular(4.0),
                                          child: TextField(
                                            controller: controllers[i],
                                            scrollController: scrollTxtControllers[i],
                                            expands: true,
                                            maxLines: null,
                                            style: TextStyle(
                                              color: thmSelected == thm.sombre ? const Color(0xffebebeb) : Colors.black,
                                              fontSize: fontSize,
                                              height: lineHeight,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onChanged: (val) {
                                              // Convertir les tabulations en espaces à la saisie
                                              if (convertTabsToSpace && val.contains('\t')) {
                                                final newText = controllers[i].text.replaceAll('\t', ' ' * spacesPerTab.toInt());
                                                final pos = controllers[i].selection.start;
                                                controllers[i].value = TextEditingValue(
                                                  text: newText,
                                                  selection: TextSelection.collapsed(
                                                    offset: pos.clamp(0, newText.length),
                                                  ),
                                                );
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        )
                                      : Scrollbar(
                                          controller: scrollTxtControllers[i],
                                          thumbVisibility: true,
                                          thickness: 8.0,
                                          radius: Radius.circular(4.0),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  controller: scrollTxtControllers[i],
                                                  scrollDirection: Axis.vertical,
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        width: 50,
                                                        child: showLineNumbers
                                                            ? LineNumbers(
                                                                text: controllers[i].text,
                                                                fontSize: fontSize,
                                                                lineHeight: lineHeight,
                                                                availableWidth: 0,
                                                                wrap: false,
                                                                thmSelected: thmSelected,
                                                              )
                                                            : const SizedBox.shrink(),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: SingleChildScrollView(
                                                          controller: scrollTxtHControllers[i],
                                                          scrollDirection: Axis.horizontal,
                                                          child: IntrinsicWidth(
                                                            child: TextField(
                                                              controller: controllers[i],
                                                              expands: false,
                                                              maxLines: null,
                                                              textAlignVertical: TextAlignVertical.top,
                                                              style: TextStyle(
                                                                color: thmSelected == thm.sombre
                                                                    ? const Color(0xffebebeb)
                                                                    : Colors.black,
                                                                fontSize: fontSize,
                                                                height: lineHeight,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                border: InputBorder.none,
                                                                contentPadding: EdgeInsets.zero,
                                                                isCollapsed: true,
                                                              ),
                                                              onChanged: (val) {
                                                                if (convertTabsToSpace && val.contains('\t')) {
                                                                  final newText = controllers[i].text.replaceAll('\t', ' ' * spacesPerTab.toInt());
                                                                  final pos = controllers[i].selection.start;
                                                                  controllers[i].value = TextEditingValue(
                                                                    text: newText,
                                                                    selection: TextSelection.collapsed(
                                                                      offset: pos.clamp(0, newText.length),
                                                                    ),
                                                                  );
                                                                }
                                                                setState(() {});
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Scrollbar(
                                                controller: scrollHBarControllers[i],
                                                thumbVisibility: true,
                                                thickness: 8.0,
                                                radius: Radius.circular(4.0),
                                                child: SingleChildScrollView(
                                                  controller: scrollHBarControllers[i],
                                                  scrollDirection: Axis.horizontal,
                                                  child: SizedBox(
                                                    width: _computeMaxLineWidth(i),
                                                    height: 8.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- widgets helpers ----------

  Widget _drawerButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 36.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
          foregroundColor: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
          textStyle: TextStyle(fontSize: 20, fontFamily: 'JetBrains Mono'),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _settingRow(String label, {required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(label,
            style: TextStyle(fontSize: 14,
                color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        SizedBox(height: 36.0, width: 55.0, child: child),
      ],
    );
  }

  Widget _switch(bool value, void Function(bool) onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xff1b72e8),
      activeTrackColor: const Color(0xff1e3553),
      inactiveThumbColor: thmSelected == thm.sombre ? const Color(0xFFB9B9B9) : const Color(0xffececec),
      inactiveTrackColor: const Color(0xff636363),
    );
  }

  Widget _radioRow(String label, thm value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
          style: TextStyle(fontSize: 14,
              color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black),
        ),
        Radio<thm>(
          value: value,
          groupValue: thmSelected,
          onChanged: (thm? v) {
            setState(() {
              thmSelected = v!;
              for (final c in controllers) {
                c.thmSelected = thmSelected;
                c.notifyListeners();
              }
            });
          },
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) return Color(0xff1b72e8);
            if (states.contains(WidgetState.hovered)) return Color(0xff676767);
            return thmSelected == thm.sombre ? Color(0x1fffffff) : Colors.black;
          }),
        ),
      ],
    );
  }
}

// ============================================================
//  LineNumbers
// ============================================================

class LineNumbers extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final double availableWidth;
  final bool wrap;
  final thm thmSelected;

  const LineNumbers({
    super.key,
    required this.text,
    required this.fontSize,
    required this.lineHeight,
    required this.availableWidth,
    required this.wrap,
    required this.thmSelected,
  });

  double _getLineHeight() {
    final painter = TextPainter(
      text: TextSpan(
        text: "A",
        style: TextStyle(fontSize: fontSize, height: lineHeight, fontFamily: 'JetBrains Mono'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.preferredLineHeight;
  }

  int _countVisualLines(String line) {
    if (!wrap || availableWidth <= 0) return 1;
    if (line.isEmpty) return 1;
    final painter = TextPainter(
      text: TextSpan(
        text: line,
        style: TextStyle(fontSize: fontSize, height: lineHeight, fontFamily: 'JetBrains Mono'),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: availableWidth);
    return painter.computeLineMetrics().length;
  }

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final lineH = _getLineHeight();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < lines.length; i++)
          SizedBox(
            height: _countVisualLines(lines[i]) * lineH,
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                "${i + 1}",
                style: TextStyle(
                  color: thmSelected == thm.sombre
                      ? const Color(0xffbdc1c6)
                      : const Color(0xff888888),
                  fontSize: fontSize,
                  height: lineHeight,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
//  SyntaxController
// ============================================================

class SyntaxController extends TextEditingController {
  TextStyle baseStyle;
  thm thmSelected;
  List<int> searchMatches = [];
  int searchMatchLen = 0;
  int currentMatchIndex = -1;

  SyntaxController({
    super.text,
    required this.baseStyle,
    required this.thmSelected,
  });

  static final symbolRegex = RegExp(r'[()\[\]{}<>.,;:=+\-*/!?&|%^~@#]');
  static final urlRegex = RegExp(r"https?://[^\s')\]>]+");

  int? findMatchingParen(String text, int index) {
    if (index < 0 || index >= text.length) return null;
    final char = text[index];
    const pairs = {'(': ')', ')': '(', '[': ']', ']': '[', '{': '}', '}': '{'};
    if (!pairs.containsKey(char)) return null;
    final closing = pairs[char]!;
    final forward = '([{'.contains(char);
    int depth = 0;
    if (forward) {
      for (int i = index; i < text.length; i++) {
        if (text[i] == char) depth++;
        if (text[i] == closing) depth--;
        if (depth == 0) return i;
      }
    } else {
      for (int i = index; i >= 0; i--) {
        if (text[i] == char) depth++;
        if (text[i] == closing) depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }

  Color _dark(String variable) {
    switch (variable) {
      // CSS: --ta-token-comment-color: #75715e
      case 'comment':     return const Color(0xff75715e);
      // CSS: --ta-token-string-color: #e6db74
      case 'string':      return const Color(0xffe6db74);
      // CSS: --ta-token-number-color: #ae81ff
      case 'number':      return const Color(0xffae81ff);
      // CSS: --ta-token-keyword-color: #f92672
      case 'keyword':     return const Color(0xfff92672);
      // CSS: --ta-token-type-color: #ae81ff
      case 'type':        return const Color(0xffae81ff);
      // CSS: --ta-token-builtin-color: #9fb4d6
      case 'builtin':     return const Color(0xff9fb4d6);
      // CSS: --ta-token-definition-color: #fd971f
      case 'definition':  return const Color(0xfffd971f);
      // CSS: --ta-token-variable-color: #a6e22e (function calls mapped to variable color)
      case 'function':    return const Color(0xffa6e22e);
      // CSS: --ta-token-variable-color: #a6e22e
      case 'variable':    return const Color(0xffa6e22e);
      // CSS: --ta-token-property-color: #a6e22e
      case 'property':    return const Color(0xffa6e22e);
      // CSS: --ta-token-tag-color: #f92672
      case 'tag':         return const Color(0xfff92672);
      // CSS: --ta-token-attribute-color: #a6e22e
      case 'attribute':   return const Color(0xffa6e22e);
      // CSS: --ta-token-meta-color: #8f8f8f
      case 'meta':        return const Color(0xff8f8f8f);
      // CSS: --ta-token-invalid-background-color: #f92672, --ta-token-invalid-color: #f8f8f0
      case 'invalid':     return const Color(0xfff8f8f0);
      // CSS: --ta-token-inserted-color: #292 → #229922
      case 'inserted':    return const Color(0xff229922);
      // CSS: --ta-token-deleted-color: #d44 → #dd4444
      case 'deleted':     return const Color(0xffdd4444);
      // CSS: --ta-token-url-color: var(--ta-token-string-color) → #e6db74
      case 'url':         return const Color(0xffe6db74);
      // CSS: --ta-token-variable-special-color: #9effff
      case 'text':        return const Color(0xfff8f8f2);
      default:            return const Color(0xfff8f8f2);
    }
  }

  Color _light(String variable) {
    switch (variable) {
      // CSS: --ta-token-comment-color: #a50  → #aa5500
      case 'comment':     return const Color(0xffaa5500);
      // CSS: --ta-token-string-color: #a11  → #aa1111
      case 'string':      return const Color(0xffaa1111);
      // CSS: --ta-token-number-color: #164  → #116644
      case 'number':      return const Color(0xff116644);
      // CSS: --ta-token-keyword-color: #708  → #770088
      case 'keyword':     return const Color(0xff770088);
      // CSS: --ta-token-type-color: #219  → #221199
      case 'type':        return const Color(0xff221199);
      // CSS: --ta-token-builtin-color: #30a  → #3300aa
      case 'builtin':     return const Color(0xff3300aa);
      // CSS: --ta-token-definition-color: #00f  → blue
      case 'definition':  return const Color(0xff0000ff);
      // CSS: --ta-token-variable-special-color: #00c → #0000cc (function calls etc.)
      case 'function':    return const Color(0xff0000cc);
      // CSS: --ta-token-variable-color: black
      case 'variable':    return Colors.black;
      // CSS: --ta-token-property-color: black
      case 'property':    return Colors.black;
      // CSS: --ta-token-tag-color: #170  → #117700
      case 'tag':         return const Color(0xff117700);
      // CSS: --ta-token-attribute-color: #00c → #0000cc
      case 'attribute':   return const Color(0xff0000cc);
      // CSS: --ta-token-meta-color: #555  → #555555
      case 'meta':        return const Color(0xff555555);
      // CSS: --ta-token-invalid-color: #f00
      case 'invalid':     return const Color(0xffff0000);
      // CSS: --ta-token-inserted-color: #292 → #229922
      case 'inserted':    return const Color(0xff229922);
      // CSS: --ta-token-deleted-color: #d44 → #dd4444
      case 'deleted':     return const Color(0xffdd4444);
      // CSS: --ta-token-url-color: var(--ta-token-string-color) → #aa1111
      case 'url':         return const Color(0xffaa1111);
      case 'text':        return Colors.black;
      default:            return Colors.black;
    }
  }

  Color _c(String variable) =>
      thmSelected == thm.sombre ? _dark(variable) : _light(variable);

  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    if (newValue.text.endsWith('\n')) {
      final lastLine = oldText.split('\n').last;
      final indent = RegExp(r'^\s*').stringMatch(lastLine) ?? '';
      newValue = newValue.copyWith(
        text: newValue.text + indent,
        selection: TextSelection.collapsed(
          offset: newValue.text.length + indent.length,
        ),
      );
    }
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <TextSpan>[];
    final cursor = selection.start.clamp(0, text.length);
    final highlightColor = _c('text');
    final matchIndex = findMatchingParen(text, cursor - 1);

    // Build a set of search match ranges for quick lookup
    final matchSet = <int, int>{}; // start -> matchIndex
    for (int mi = 0; mi < searchMatches.length; mi++) {
      matchSet[searchMatches[mi]] = mi;
    }

    // Colors from the CSS
    // dark: rgba(253,207,76,.5) → 0x80fdcf4c  (other matches), current: brighter
    // light: rgb(26,115,232,0.18) → 0x2e1a73e8 (other matches), current: 0x461a73e8
    final Color searchHighlightColor = thmSelected == thm.sombre
        ? const Color(0x80fdcf4c)
        : const Color(0x2e1a73e8);
    final Color searchCurrentColor = thmSelected == thm.sombre
        ? const Color(0xb0fdcf4c)
        : const Color(0x5a1a73e8);

    int i = 0;

    while (i < text.length) {
      // Check if we're at the start of a search match
      if (searchMatchLen > 0 && matchSet.containsKey(i)) {
        final mi = matchSet[i]!;
        final end = (i + searchMatchLen).clamp(0, text.length);
        final matchText = text.substring(i, end);
        final bgColor = mi == currentMatchIndex ? searchCurrentColor : searchHighlightColor;
        // We paint the matched text with a background highlight using a WidgetSpan trick
        // Since TextSpan doesn't support background directly for arbitrary ranges,
        // we use TextStyle backgroundColor
        children.add(TextSpan(
          text: matchText,
          style: baseStyle.copyWith(backgroundColor: bgColor),
        ));
        i = end;
        continue;
      }

      // Commentaire //
      if (text.startsWith("//", i)) {
        final end = text.indexOf('\n', i);
        final commentText = end == -1 ? text.substring(i) : text.substring(i, end);
        // Check if any part of this comment overlaps a search match — handled char by char for simplicity
        // For comments, just check start
        final urlMatch = urlRegex.firstMatch(commentText);
        if (urlMatch != null) {
          if (urlMatch.start > 0) {
            children.add(TextSpan(text: commentText.substring(0, urlMatch.start), style: baseStyle.copyWith(color: _c('comment'))));
          }
          children.add(TextSpan(text: urlMatch.group(0), style: baseStyle.copyWith(color: _c('url'), decoration: TextDecoration.underline, decorationColor: _c('url'))));
          if (urlMatch.end < commentText.length) {
            children.add(TextSpan(text: commentText.substring(urlMatch.end), style: baseStyle.copyWith(color: _c('comment'))));
          }
        } else {
          children.add(TextSpan(text: commentText, style: baseStyle.copyWith(color: _c('comment'))));
        }
        i += commentText.length;
        continue;
      }

      // Commentaire /* */
      if (text.startsWith("/*", i)) {
        final end = text.indexOf("*/", i + 2);
        final commentText = end == -1 ? text.substring(i) : text.substring(i, end + 2);
        children.add(TextSpan(text: commentText, style: baseStyle.copyWith(color: _c('comment'))));
        i += commentText.length;
        continue;
      }

      // String " ' `
      if (text[i] == '"' || text[i] == "'" || text[i] == '`') {
        final quote = text[i];
        int end = i + 1;
        while (end < text.length) {
          if (text[end] == '\\') { end += 2; continue; }
          if (text[end] == quote) { end++; break; }
          end++;
        }
        final strText = text.substring(i, end);
        final urlMatch = urlRegex.firstMatch(strText);
        if (urlMatch != null) {
          if (urlMatch.start > 0) {
            children.add(TextSpan(text: strText.substring(0, urlMatch.start), style: baseStyle.copyWith(color: _c('string'))));
          }
          children.add(TextSpan(text: urlMatch.group(0), style: baseStyle.copyWith(color: _c('url'), decoration: TextDecoration.underline, decorationColor: _c('url'))));
          if (urlMatch.end < strText.length) {
            children.add(TextSpan(text: strText.substring(urlMatch.end), style: baseStyle.copyWith(color: _c('string'))));
          }
        } else {
          children.add(TextSpan(text: strText, style: baseStyle.copyWith(color: _c('string'))));
        }
        i = end;
        continue;
      }

      // Décorateur @
      if (text[i] == '@') {
        final match = RegExp(r'@[a-zA-Z_][a-zA-Z0-9_]*').matchAsPrefix(text, i);
        if (match != null) {
          children.add(TextSpan(text: match.group(0), style: baseStyle.copyWith(color: _c('meta'))));
          i = match.end;
          continue;
        }
      }

      // Symboles
      final symbolMatch = symbolRegex.matchAsPrefix(text, i);
      if (symbolMatch != null) {
        TextStyle spanStyle = baseStyle.copyWith(color: _c('text'));
        if (i == cursor - 1 || i == matchIndex) {
          spanStyle = spanStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: highlightColor,
            decorationThickness: 4.0,
          );
        }
        children.add(TextSpan(text: symbolMatch.group(0), style: spanStyle));
        i = symbolMatch.end;
        continue;
      }

      // Nombre
      final numMatch = RegExp(r'\b\d+(?:\.\d+)?\b').matchAsPrefix(text, i);
      if (numMatch != null) {
        children.add(TextSpan(text: numMatch.group(0), style: baseStyle.copyWith(color: _c('number'))));
        i = numMatch.end;
        continue;
      }

      // Identifiants et mots-clés
      final wordMatch = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b').matchAsPrefix(text, i);
      if (wordMatch != null) {
        final word = wordMatch.group(0)!;
        TextStyle spanStyle = baseStyle;

        if (i == cursor - 1 || i == matchIndex) {
          spanStyle = spanStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: highlightColor,
            decorationThickness: 2.0,
          );
        }

        const keywords = {
          'type', 'interface', 'class', 'extends', 'implements', 'keyof',
          'infer', 'readonly', 'abstract', 'declare', 'namespace', 'module',
          'export', 'import', 'from', 'as', 'of', 'in', 'instanceof', 'typeof',
          'void', 'never', 'unknown', 'any', 'null', 'undefined', 'true', 'false',
          'async', 'await', 'try', 'catch', 'finally', 'throw', 'return',
          'const', 'let', 'var', 'new', 'delete', 'if', 'else', 'for', 'while',
          'do', 'switch', 'case', 'break', 'continue', 'default', 'yield',
          'static', 'public', 'private', 'protected', 'override', 'get', 'set',
          'super', 'this',
        };

        const builtinTypes = {
          'string', 'number', 'boolean', 'object', 'symbol', 'bigint',
          'Promise', 'Array', 'Map', 'Set', 'Record', 'Partial', 'Required',
          'Readonly', 'Pick', 'Omit', 'Exclude', 'Extract', 'NonNullable',
          'ReturnType', 'InstanceType', 'Parameters', 'ConstructorParameters', 'Awaited',
        };

        const builtinGlobals = {
          'console', 'fetch', 'Error', 'Math', 'JSON', 'Object', 'Date',
          'RegExp', 'Symbol', 'globalThis', 'window', 'document', 'process',
          'setTimeout', 'setInterval', 'clearTimeout', 'clearInterval',
          'queueMicrotask', 'requestAnimationFrame', 'cancelAnimationFrame',
          'performance', 'crypto', 'URL', 'URLSearchParams', 'FormData',
          'Headers', 'Request', 'Response', 'EventTarget', 'CustomEvent',
          'AbortController', 'AbortSignal', 'WeakMap', 'WeakSet', 'WeakRef',
          'FinalizationRegistry', 'Proxy', 'Reflect', 'Intl', 'ArrayBuffer',
          'SharedArrayBuffer', 'DataView', 'Generator', 'AsyncGenerator',
        };

        final afterWord = wordMatch.end < text.length ? text[wordMatch.end] : '';
        final isFunction = afterWord == '(' ||
            (wordMatch.end < text.length - 1 && text.substring(wordMatch.end).trimLeft().startsWith('('));

        if (keywords.contains(word)) {
          spanStyle = spanStyle.copyWith(color: _c('keyword'));
        } else if (builtinTypes.contains(word)) {
          spanStyle = spanStyle.copyWith(color: _c('type'));
        } else if (builtinGlobals.contains(word)) {
          spanStyle = spanStyle.copyWith(color: _c('builtin'));
        } else if (RegExp(r'^[A-Z]').hasMatch(word)) {
          spanStyle = spanStyle.copyWith(color: _c('definition'));
        } else if (isFunction) {
          spanStyle = spanStyle.copyWith(color: _c('function'));
        } else {
          spanStyle = spanStyle.copyWith(color: _c('variable'));
        }

        children.add(TextSpan(text: word, style: spanStyle));
        i = wordMatch.end;
        continue;
      }

      // Caractère non reconnu
      TextStyle spanStyle = baseStyle.copyWith(color: _c('variable'));
      if (i == cursor - 1 || i == matchIndex) {
        spanStyle = spanStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: highlightColor,
          decorationThickness: 2.0,
        );
      }
      children.add(TextSpan(text: text[i], style: spanStyle));
      i++;
    }

    return TextSpan(
      style: baseStyle.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      children: children,
    );
  }
} //Erreurs : alignement remplacer mode ordi, scroll recherche h, coloration ``
