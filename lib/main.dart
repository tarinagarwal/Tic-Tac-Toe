import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white),
      ),
      themeMode: ThemeMode.system,
      home: const TicTacToeGame(),
    );
  }
}

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({Key? key}) : super(key: key);

  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame>
    with TickerProviderStateMixin {
  List<List<String>> board = List.generate(3, (_) => List.filled(3, ''));
  bool xTurn = true;
  String winner = '';
  bool singlePlayerMode = false;
  List<Map<String, dynamic>> gameHistory = [];
  late AnimationController _controller;
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      xWins = prefs.getInt('xWins') ?? 0;
      oWins = prefs.getInt('oWins') ?? 0;
      draws = prefs.getInt('draws') ?? 0;
    });
  }

  void _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xWins', xWins);
    await prefs.setInt('oWins', oWins);
    await prefs.setInt('draws', draws);
  }

  void _handleTap(int row, int col) {
    if (board[row][col] == '' && winner == '' && !isGameOver) {
      setState(() {
        board[row][col] = xTurn ? 'X' : 'O';
        xTurn = !xTurn;
        winner = _checkWinner();
        gameHistory.add({
          'board': List.generate(3, (i) => List.from(board[i])),
          'player': xTurn ? 'O' : 'X',
        });

        if (winner != '') {
          isGameOver = true;
          if (winner == 'X') {
            xWins++;
          } else if (winner == 'O') {
            oWins++;
          } else {
            draws++;
          }
          _saveStats();
        }
      });

      _controller.forward(from: 0);

      if (singlePlayerMode && winner == '' && !xTurn && !isGameOver) {
        Timer(const Duration(milliseconds: 500), () => _makeAIMove());
      }
    }
  }

  void _makeAIMove() {
    if (isGameOver) return;

    // Simple AI: Look for winning move, then blocking move, then random
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          // Check if AI can win
          board[i][j] = 'O';
          if (_checkWinner() == 'O') {
            _handleTap(i, j);
            return;
          }
          board[i][j] = '';

          // Check if AI needs to block
          board[i][j] = 'X';
          if (_checkWinner() == 'X') {
            board[i][j] = '';
            _handleTap(i, j);
            return;
          }
          board[i][j] = '';
        }
      }
    }

    // If no winning or blocking move, choose random empty cell
    List<int> emptyCells = [];
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          emptyCells.add(i * 3 + j);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      int aiMove = emptyCells[Random().nextInt(emptyCells.length)];
      int row = aiMove ~/ 3;
      int col = aiMove % 3;
      _handleTap(row, col);
    }
  }

  String _checkWinner() {
    // Check rows, columns, and diagonals
    for (int i = 0; i < 3; i++) {
      if (board[i][0] != '' &&
          board[i][0] == board[i][1] &&
          board[i][1] == board[i][2]) {
        return board[i][0];
      }
      if (board[0][i] != '' &&
          board[0][i] == board[1][i] &&
          board[1][i] == board[2][i]) {
        return board[0][i];
      }
    }
    if (board[0][0] != '' &&
        board[0][0] == board[1][1] &&
        board[1][1] == board[2][2]) {
      return board[0][0];
    }
    if (board[0][2] != '' &&
        board[0][2] == board[1][1] &&
        board[1][1] == board[2][0]) {
      return board[0][2];
    }

    // Check for draw
    if (!board.any((row) => row.any((cell) => cell == ''))) {
      return 'Draw';
    }

    return '';
  }

  void _resetGame() {
    setState(() {
      board = List.generate(3, (_) => List.filled(3, ''));
      xTurn = true;
      winner = '';
      isGameOver = false;
      gameHistory.clear();
    });
  }

  void _toggleGameMode() {
    setState(() {
      singlePlayerMode = !singlePlayerMode;
      _resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TicTacToe', style: GoogleFonts.pressStart2p()),
        actions: [
          IconButton(
            icon: Icon(singlePlayerMode ? Icons.person : Icons.people),
            onPressed: _toggleGameMode,
            tooltip: singlePlayerMode
                ? 'Switch to Two Players'
                : 'Switch to Single Player',
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            winner == ''
                ? 'Current Turn: ${xTurn ? 'X' : 'O'}'
                : winner == 'Draw'
                    ? 'Game Over: Draw'
                    : 'Game Over: $winner Wins!',
            style: GoogleFonts.pressStart2p(
                fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                int row = index ~/ 3;
                int col = index % 3;
                return GestureDetector(
                  onTap: () => _handleTap(row, col),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + _controller.value * 0.1,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Center(
                        child: Text(
                          board[row][col],
                          style: GoogleFonts.pressStart2p(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _resetGame,
                child: Text('Reset Game',
                    style: GoogleFonts.pressStart2p(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton(
                onPressed: () => _showGameHistory(context),
                child: Text('Game History',
                    style: GoogleFonts.pressStart2p(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Stats',
            style: GoogleFonts.pressStart2p(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('X Wins', xWins),
              _buildStatCard('O Wins', oWins),
              _buildStatCard('Draws', draws),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.pressStart2p(fontSize: 12)),
            const SizedBox(height: 4),
            Text('$value',
                style: GoogleFonts.pressStart2p(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showGameHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game History', style: GoogleFonts.pressStart2p()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: gameHistory.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    'Move ${index + 1}: Player ${gameHistory[index]['player']}',
                    style: GoogleFonts.pressStart2p(fontSize: 12),
                  ),
                  onTap: () =>
                      _showBoardState(context, gameHistory[index]['board']),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: GoogleFonts.pressStart2p()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showBoardState(BuildContext context, List<List<String>> boardState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Board State', style: GoogleFonts.pressStart2p()),
          content: SizedBox(
            width: 200,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                int row = index ~/ 3;
                int col = index % 3;
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      boardState[row][col],
                      style: GoogleFonts.pressStart2p(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: GoogleFonts.pressStart2p()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
