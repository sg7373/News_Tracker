import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/sports_service.dart';

class LiveScoreScreen extends StatefulWidget {
  const LiveScoreScreen({super.key});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  final SportsService _sportsService = SportsService();

  List<MatchScore> _footballMatches = [];
  List<MatchScore> _cricketMatches = [];
  bool _isLoading = true;
  String? _error;
  bool _isMockMode = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchScores();
    // Auto-refresh scores every 10 seconds for closer to real-time updates
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isLoading) {
        _fetchScores(isBackgroundRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchScores({bool isBackgroundRefresh = false}) async {
    if (!isBackgroundRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _isMockMode = false;
        });
      }
    }

    try {
      bool limitHit = false;
      String? limitMsg;

      // Fetch both in parallel but catch errors independently
      final results = await Future.wait([
        _sportsService.fetchFootballMatches().catchError((e) {
          final err = e.toString().toLowerCase();
          if (err.contains('limit') || err.contains('reached') || err.contains('rate')) {
            limitHit = true;
            limitMsg = "Football API Limit Reached (Free Plan).";
          } else {
            setState(() => _error = (_error == null) ? "Football: $e" : "$_error\nFootball: $e");
          }
          return <MatchScore>[];
        }),
        _sportsService.fetchCricketMatches().catchError((e) {
          final err = e.toString().toLowerCase();
          if (err.contains('limit') || err.contains('blocked') || err.contains('rate')) {
            limitHit = true;
            limitMsg = (limitMsg == null) ? "Cricket API Limit Reached." : "$limitMsg & Cricket API Limit.";
          } else {
            setState(() => _error = (_error == null) ? "Cricket: $e" : "$_error\nCricket: $e");
          }
          return <MatchScore>[];
        }),
      ]);

      if (mounted) {
        if (limitHit) {
          setState(() {
            _isMockMode = true;
            _footballMatches = _sportsService.getMockFootballMatches();
            _cricketMatches = _sportsService.getMockCricketMatches();
            _error = limitMsg ?? "API Limit Reached. Showing Mock Data.";
            _isLoading = false;
          });
        } else {
          setState(() {
            _footballMatches = results[0];
            _cricketMatches = results[1];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Internal error
      if (mounted) {
        setState(() {
          if (!isBackgroundRefresh) _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    final bool hasData = _footballMatches.isNotEmpty || _cricketMatches.isNotEmpty;

    if (_error != null && !_isMockMode && !hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load scores', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchScores,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final bool noData = _footballMatches.isEmpty && _cricketMatches.isEmpty;

    if (noData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No live matches right now',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchScores,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchScores,
      color: Colors.red,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0),
        children: [
          const SizedBox(height: 12),
          if (_cricketMatches.isNotEmpty) ...[
            _sectionHeader('🏏 Cricket Match Center'),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cricketMatches.length,
                itemBuilder: (context, index) {
                  return _matchCard(_cricketMatches[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_footballMatches.isNotEmpty) ...[
            _sectionHeader('⚽ Football Match Center'),
            SizedBox(
              
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _footballMatches.length,
                itemBuilder: (context, index) {
                  return _matchCard(_footballMatches[index]);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _getBadgeColor(String matchType) {
    matchType = matchType.toUpperCase();
    if (matchType.contains('ODI')) return Colors.blue.shade700;
    if (matchType.contains('FC') || matchType.contains('TEST')) return Colors.red.shade600;
    return Colors.grey.shade800; // T20I, etc.
  }

  Widget _matchCard(MatchScore match) {
    final title = match.venue.isNotEmpty ? match.venue : match.sport;
    final badgeColor = _getBadgeColor(match.matchType);
    final statusColor = match.isLive ? Colors.red.shade600 : Colors.blue.shade600;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (match.matchType.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.matchType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Teams and Scores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _teamRow(match.teamA, match.sport == 'football' ? match.score.split(' - ').first : (match.score.contains('vs') ? match.score.split(' vs ').first : match.score)),
                const SizedBox(height: 8),
                _teamRow(match.teamB, match.sport == 'football' ? match.score.split(' - ').last : (match.score.contains('vs') ? match.score.split(' vs ').last : '-')),
              ],
            ),
          ),
          
          // Status line
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                if (match.isLive) _PulseDot(),
                Expanded(
                  child: Text(
                    match.isLive ? 'Live · ${match.status}' : (match.date.isNotEmpty ? '${match.date} · ${match.status}' : match.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('POINTS TABLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(width: 16),
                Text('SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamRow(String name, String score) {
    if (score == '-' || score == name) score = ''; 

    return Row(
      children: [
        // Placeholder Flag/Icon
        Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Icon(Icons.flag, size: 12, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (score.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              score,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: 6),
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
