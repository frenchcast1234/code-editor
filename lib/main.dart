import 'dart:io';
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
  final TextEditingController _consoleController = TextEditingController();
  final FocusNode _consoleFocusNode = FocusNode();

  // Recherche
  String _searchQuery = '';
  int _searchCurrentMatch = 0;
  List<int> _searchMatches = [];

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

  // ---------- helpers pour ajouter un onglet ----------
  void _addTab({String? name, String? path, String content = ''}) {
    final tabName = name ?? 'Nouveau fichier ${fileNames.length + 1}';
    fileNames.add(tabName);
    filePaths.add(path);
    fileModified.add(false);
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
    setState(() {
      _searchQuery = query;
      _searchMatches = [];
      _searchCurrentMatch = 0;
      if (query.isEmpty) return;
      final text = controllers[currentIndex].text;
      int start = 0;
      while (true) {
        final idx = text.indexOf(query, start);
        if (idx == -1) break;
        _searchMatches.add(idx);
        start = idx + query.length;
      }
    });
  }

  void _searchNext() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _searchCurrentMatch = (_searchCurrentMatch + 1) % _searchMatches.length;
    });
    _jumpToMatch(_searchCurrentMatch);
  }

  void _searchPrev() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _searchCurrentMatch = (_searchCurrentMatch - 1 + _searchMatches.length) % _searchMatches.length;
    });
    _jumpToMatch(_searchCurrentMatch);
  }

  void _jumpToMatch(int matchIdx) {
    final pos = _searchMatches[matchIdx];
    controllers[currentIndex].selection = TextSelection(
      baseOffset: pos,
      extentOffset: pos + _searchQuery.length,
    );
  }

  @override
  void initState() {
    super.initState();
    for (int k = 0; k < controllers.length; k++) {
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
    }
    // Écouter les modifications pour marquer le fichier comme non sauvegardé
    for (int k = 0; k < controllers.length; k++) {
      final idx = k;
      controllers[k].addListener(() {
        if (!fileModified[idx]) {
          setState(() => fileModified[idx] = true);
        }
      });
    }
    // Initialiser la recherche sur le controller de recherche
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
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.arrow_back),
              color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
              tooltip: 'Annuler',
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.arrow_forward),
              color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
              tooltip: 'Rétablir',
            ),
            IconButton(
              onPressed: () {},
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: thmSelected == thm.sombre ? Color(0xff1f1f1f) : Colors.white,
                      border: Border(bottom: BorderSide(
                        color: thmSelected == thm.sombre ? Color(0x1fffffff) : Color(0x0a000000),
                        width: 2.0,
                      )),
                    ),
                    height: 48,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      height: 30,
                      width: double.infinity,
                      alignment: Alignment.center,
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
                              controller: _searchController,
                              style: TextStyle(
                                color: thmSelected == thm.sombre ? Color(0xffebebeb) : Colors.black,
                                fontSize: 14,
                                height: 1.0,
                              ),
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Rechercher...',
                                hintStyle: TextStyle(
                                  color: thmSelected == thm.sombre ? Color(0x55ffffff) : Color(0x55000000),
                                  fontSize: 14,
                                ),
                                contentPadding: EdgeInsets.only(left: 16.0),
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
                                style: TextStyle(fontSize: 11,
                                    color: thmSelected == thm.sombre ? Color(0x99ffffff) : Color(0x99000000)),
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
                                    final controller = controllers[i];
                                    final text = controller.text;
                                    final selection = controller.selection;
                                    final tabSize = spacesPerTab.toInt();

                                    if (selection.isCollapsed) {
                                      final cursor = selection.start.clamp(0, text.length);

                                      final lineStartRaw = text.lastIndexOf('\n', cursor - 1);
                                      final lineStart = lineStartRaw == -1 ? 0 : lineStartRaw + 1;
                                      final column = cursor - lineStart;

                                      // Tab → espaces (toujours, indépendamment de convertTabsToSpace qui agit à la saisie)
                                      if (event is KeyDownEvent &&
                                          event.logicalKey == LogicalKeyboardKey.tab) {
                                        final spacesToInsert = tabSize - (column % tabSize);
                                        controller.value = controller.value.copyWith(
                                          text: text.replaceRange(cursor, cursor, ' ' * spacesToInsert),
                                          selection: TextSelection.collapsed(offset: cursor + spacesToInsert),
                                        );
                                        return KeyEventResult.handled;
                                      }

                                      // Backspace intelligent (retrait intelligent)
                                      if (retraitIntelligent &&
                                          event is KeyDownEvent &&
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
      case 'comment':     return const Color(0xff6a9955);
      case 'string':      return const Color(0xffce9178);
      case 'number':      return const Color(0xffb5cea8);
      case 'keyword':     return const Color(0xff569cd6);
      case 'type':        return const Color(0xff4ec9b0);
      case 'builtin':     return const Color(0xffdcdcaa);
      case 'definition':  return const Color(0xff4ec9b0);
      case 'function':    return const Color(0xffdcdcaa);
      case 'variable':    return const Color(0xffebebeb);
      case 'property':    return const Color(0xff9cdcfe);
      case 'tag':         return const Color(0xff569cd6);
      case 'attribute':   return const Color(0xff9cdcfe);
      case 'meta':        return const Color(0xffc586c0);
      case 'invalid':     return const Color(0xfff44747);
      case 'inserted':    return const Color(0xffb5cea8);
      case 'deleted':     return const Color(0xffce9178);
      case 'url':         return const Color(0xff4ec9b0);
      case 'text':        return const Color(0xffebebeb);
      default:            return const Color(0xffebebeb);
    }
  }

  Color _light(String variable) {
    switch (variable) {
      case 'comment':     return const Color(0xff008000);
      case 'string':      return const Color(0xffa31515);
      case 'number':      return const Color(0xff098658);
      case 'keyword':     return const Color(0xff0000ff);
      case 'type':        return const Color(0xff267f99);
      case 'builtin':     return const Color(0xff795e26);
      case 'definition':  return const Color(0xff0000ff);
      case 'function':    return const Color(0xff0000cc);
      case 'variable':    return Colors.black;
      case 'property':    return Colors.black;
      case 'tag':         return const Color(0xff117700);
      case 'attribute':   return const Color(0xff0000cc);
      case 'meta':        return const Color(0xff555555);
      case 'invalid':     return const Color(0xffff0000);
      case 'inserted':    return const Color(0xff229922);
      case 'deleted':     return const Color(0xffdd4444);
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

    int i = 0;

    while (i < text.length) {
      // Commentaire //
      if (text.startsWith("//", i)) {
        final end = text.indexOf('\n', i);
        final commentText = end == -1 ? text.substring(i) : text.substring(i, end);
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
}