import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/scheduler.dart';


void main() {
  runApp(BunnyGameApp());
}

class BunnyGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: StartScreen());
  }
}

/* ---------------- START SCREEN ---------------- */
class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
   

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true); // bounce back and forth

    _bounceAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF1F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/bunny.png", height: 120),

            SizedBox(height: 20),

            Text(
              "Bunny Hop",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            // Bouncy Name
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: child,
                );
              },
              child: Text(
                "🐰 Made by Devna Krishna 💖",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            SizedBox(height: 30),

            pastelButton("Start Game", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GameScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }
}



/* ---------------- GAME SCREEN ---------------- */

/* ---------------- GAME SCREEN ---------------- */

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Bunny
  double bunnyY = 0.8;
  double velocity = 0;
  double gravity = 0.004;
  double jumpForce = -0.08;

  // Obstacles & Clouds
  double obstacleX = 1.2;
  double cloudX = 1.2;
  double cloudX2 = -0.3;

  // Power-ups
  double powerUpX = 1.5;
  String powerUpType = "star"; // star or shield
  bool showPowerUp = false;
  bool shieldActive = false;

  // Scores
  int score = 0;
  int highScore = 0;
  bool gameOver = false;

  late Ticker _ticker;
  Random random = Random();

  // Obstacle assets
  List<String> obstacles = [
    "assets/cactus.png",
    "assets/mushroom.png",
    "assets/pot.png",
    "assets/wood.png",
  ];
  String obstacle = "assets/cactus.png";

  // Audio
  final AudioPlayer player = AudioPlayer();
  void playJumpSound() {
    player.play(AssetSource('sounds/jump.wav'));
  }

  @override
  void initState() {
    super.initState();
    loadHighScore();

    // Start the game loop
    _ticker = createTicker((_) {
      updateGame();
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt("highScore") ?? 0;
  }

  void saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("highScore", highScore);
  }

  // Game update loop
  void updateGame() {
    if (gameOver) return;

    setState(() {
      // Bunny physics
      velocity += gravity;
      bunnyY += velocity;

      if (bunnyY > 0.8) {
        bunnyY = 0.8;
        velocity = 0;
      }
      if (bunnyY < -1.0) velocity = 0;

      // Clouds movement
      cloudX -= 0.002;
      cloudX2 -= 0.0015;
      if (cloudX < -1.5) cloudX = 1.5;
      if (cloudX2 < -1.5) cloudX2 = 1.5;

      // Obstacles movement
      double obstacleSpeed = 0.015 + score * 0.0008;
      obstacleX -= obstacleSpeed;
     if (obstacleX < -1.2) {
  obstacleX = 1.2;
  obstacle = obstacles[random.nextInt(obstacles.length)];
  
  score++; // increment score

  // Update high score immediately
  if (score > highScore) {
    highScore = score;   // update variable
    saveHighScore();     // save to SharedPreferences
  }
}

      // Power-up movement
      if (showPowerUp) {
        powerUpX -= 0.01;
        if (powerUpX < -1.2) showPowerUp = false;
      } else if (random.nextInt(200) == 0) {
        showPowerUp = true;
        powerUpX = 1.5;
        powerUpType = random.nextBool() ? "star" : "shield";
      }

      // Collision with power-up
      if (showPowerUp && powerUpX < 0.1 && powerUpX > -0.1 && bunnyY > 0.6) {
        if (powerUpType == "star") {
          score += 2;
        } else {
          activateShield();
        }
        showPowerUp = false;
      }

      // Collision with obstacle
      if ((obstacleX < 0.1 && obstacleX > -0.1) && bunnyY > 0.65 && !shieldActive) {
        gameOver = true;
        _ticker.stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GameOverScreen(score, highScore)),
        );
      }
    });
  }

  void jump() {
    if (!gameOver && bunnyY >= 0.79) {
      velocity = jumpForce;
      playJumpSound();
    }
  }

  void activateShield() {
    shieldActive = true;
    Future.delayed(Duration(seconds: 3), () {
      shieldActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: jump,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBEE7E8), Color(0xFFFFF1F7)],
            ),
          ),
          child: Stack(
            children: [
              // Clouds
              Align(
                  alignment: Alignment(cloudX, -0.8),
                  child: Image.asset("assets/cloud.png", width: 120)),
              Align(
                  alignment: Alignment(cloudX2, -0.5),
                  child: Image.asset("assets/cloud.png", width: 90)),

              // Bunny
              AnimatedAlign(
                duration: Duration(milliseconds: 60),
                alignment: Alignment(0, bunnyY),
                child: Container(
                  decoration: shieldActive
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 20)],
                        )
                      : null,
                  child: Image.asset("assets/bunny.png", width: 70),
                ),
              ),

              // Obstacle
              Align(
                alignment: Alignment(obstacleX, 0.85),
                child: Image.asset(obstacle, width: 60),
              ),

              // PowerUp
              if (showPowerUp)
                Align(
                  alignment: Alignment(powerUpX, 0.6),
                  child: Image.asset(
                      powerUpType == "star" ? "assets/star.png" : "assets/shield.png",
                      width: 40),
                ),

              // Score
              Positioned(
                top: 40,
                left: 20,
                child: Text("Score: $score  High: $highScore",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/* ---------------- GAME OVER ---------------- */

class GameOverScreen extends StatelessWidget {
  final int score;
  final int highScore;

  GameOverScreen(this.score, this.highScore);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFEFD5),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset("assets/bunny.png", height: 100),
          Text("Game Over", style: TextStyle(fontSize: 28)),
          Text("Score: $score"),
          Text("High Score: $highScore"),
          pastelButton("Play Again", () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => GameScreen()));
          })
        ]),
      ),
    );
  }
}

/* ---------------- BUTTON ---------------- */

Widget pastelButton(String text, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFBEE7E8),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    onPressed: onPressed,
    child: Text(text),
  );
}
