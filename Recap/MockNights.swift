// MockNights.swift – Demo data (matches rork-recap-nightlog reference)

let mockNights: [NightData] = [

    NightData(
        nightId: "night-2026-04-12",
        title: "Sunday Brunch & Stroll",
        dateString: "Sunday, April 12, 2026",
        dateISO: "2026-04-12",
        startTime: "10:30 AM",
        endTime: "04:15 PM",
        totalSteps: 7320,
        totalDuration: "5h 45m",
        totalStopsCount: 3,
        stops: [
            NightStop(stopId: "s1-cafe",  stopName: "Sunny Side Café",   arrivalTime: "10:45 AM", departureTime: "12:00 PM", iconType: .cafe,       latitude: 52.5200, longitude: 13.4050, dwellMinutes: 75),
            NightStop(stopId: "s1-park",  stopName: "Tiergarten Loop",   arrivalTime: "12:15 PM", departureTime: "01:30 PM", iconType: .park,       latitude: 52.5145, longitude: 13.3501, dwellMinutes: 75),
            NightStop(stopId: "s1-rest",  stopName: "Trattoria Bellini", arrivalTime: "01:45 PM", departureTime: "03:45 PM", iconType: .restaurant, latitude: 52.5160, longitude: 13.3780, dwellMinutes: 120),
            NightStop(stopId: "s1-home",  stopName: "Home Sweet Home",   arrivalTime: "04:15 PM", departureTime: "04:15 PM", iconType: .home,       latitude: 52.5260, longitude: 13.4180, dwellMinutes: 0),
        ],
        routeCoordinates: [
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
            RoutePoint(latitude: 52.5230, longitude: 13.4100),
            RoutePoint(latitude: 52.5200, longitude: 13.4050),
            RoutePoint(latitude: 52.5175, longitude: 13.3800),
            RoutePoint(latitude: 52.5145, longitude: 13.3501),
            RoutePoint(latitude: 52.5160, longitude: 13.3780),
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
        ],
        photos: [
            SessionPhoto(id: "p1-1", uri: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=400&fit=crop", timestamp: "11:15 AM", caption: "brunch"),
            SessionPhoto(id: "p1-2", uri: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=400&h=400&fit=crop", timestamp: "12:45 PM", caption: "tiergarten"),
            SessionPhoto(id: "p1-3", uri: "https://images.unsplash.com/photo-1533777324565-a040eb52facd?w=400&h=400&fit=crop", timestamp: "02:10 PM", caption: "trattoria"),
            SessionPhoto(id: "p1-4", uri: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=400&fit=crop", timestamp: "03:20 PM"),
        ],
        venueBadges: [
            VenueBadge(id: "vb1-1", name: "Sunny Side Café",   iconType: .cafe,       latitude: 52.5200, longitude: 13.4050, emoji: "☕"),
            VenueBadge(id: "vb1-2", name: "Tiergarten",        iconType: .park,       latitude: 52.5145, longitude: 13.3501, emoji: "🌳"),
            VenueBadge(id: "vb1-3", name: "Trattoria Bellini", iconType: .restaurant, latitude: 52.5160, longitude: 13.3780, emoji: "🍝"),
        ]
    ),

    NightData(
        nightId: "night-2026-04-10",
        title: "Saturday Market Run",
        dateString: "Saturday, April 10, 2026",
        dateISO: "2026-04-10",
        startTime: "09:30 AM",
        endTime: "01:00 PM",
        totalSteps: 6120,
        totalDuration: "3h 30m",
        totalStopsCount: 2,
        stops: [
            NightStop(stopId: "s4-cafe", stopName: "Morning Roasters", arrivalTime: "09:45 AM", departureTime: "10:45 AM", iconType: .cafe, latitude: 52.5210, longitude: 13.4090, dwellMinutes: 60),
            NightStop(stopId: "s4-park", stopName: "Volkspark",        arrivalTime: "11:00 AM", departureTime: "12:30 PM", iconType: .park, latitude: 52.5310, longitude: 13.4240, dwellMinutes: 90),
            NightStop(stopId: "s4-home", stopName: "Home Sweet Home",  arrivalTime: "01:00 PM", departureTime: "01:00 PM", iconType: .home, latitude: 52.5260, longitude: 13.4180, dwellMinutes: 0),
        ],
        routeCoordinates: [
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
            RoutePoint(latitude: 52.5210, longitude: 13.4090),
            RoutePoint(latitude: 52.5270, longitude: 13.4160),
            RoutePoint(latitude: 52.5310, longitude: 13.4240),
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
        ],
        photos: [
            SessionPhoto(id: "p4-1", uri: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=400&fit=crop", timestamp: "10:00 AM"),
            SessionPhoto(id: "p4-2", uri: "https://images.unsplash.com/photo-1500673922987-e212871fec22?w=400&h=400&fit=crop", timestamp: "11:30 AM"),
            SessionPhoto(id: "p4-3", uri: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&h=400&fit=crop", timestamp: "12:15 PM"),
        ],
        venueBadges: [
            VenueBadge(id: "vb4-1", name: "Morning Roasters", iconType: .cafe, latitude: 52.5210, longitude: 13.4090, emoji: "☕"),
            VenueBadge(id: "vb4-2", name: "Volkspark",        iconType: .park, latitude: 52.5310, longitude: 13.4240, emoji: "🌳"),
        ]
    ),

    NightData(
        nightId: "night-2026-04-07",
        title: "Friday Adventure",
        dateString: "Friday, April 7, 2026",
        dateISO: "2026-04-07",
        startTime: "06:30 PM",
        endTime: "11:45 PM",
        totalSteps: 9820,
        totalDuration: "5h 15m",
        totalStopsCount: 3,
        stops: [
            NightStop(stopId: "s2-rest",  stopName: "Noodle House",      arrivalTime: "07:00 PM", departureTime: "08:30 PM", iconType: .restaurant, latitude: 52.5180, longitude: 13.3950, dwellMinutes: 90),
            NightStop(stopId: "s2-bar",   stopName: "Rooftop Sunset Bar", arrivalTime: "08:45 PM", departureTime: "10:30 PM", iconType: .bar,        latitude: 52.5220, longitude: 13.4080, dwellMinutes: 105),
            NightStop(stopId: "s2-club",  stopName: "Pulse Club",         arrivalTime: "10:45 PM", departureTime: "11:30 PM", iconType: .club,       latitude: 52.5105, longitude: 13.4205, dwellMinutes: 45),
            NightStop(stopId: "s2-home",  stopName: "Home Sweet Home",    arrivalTime: "11:45 PM", departureTime: "11:45 PM", iconType: .home,       latitude: 52.5260, longitude: 13.4180, dwellMinutes: 0),
        ],
        routeCoordinates: [
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
            RoutePoint(latitude: 52.5220, longitude: 13.4060),
            RoutePoint(latitude: 52.5180, longitude: 13.3950),
            RoutePoint(latitude: 52.5200, longitude: 13.4000),
            RoutePoint(latitude: 52.5220, longitude: 13.4080),
            RoutePoint(latitude: 52.5150, longitude: 13.4150),
            RoutePoint(latitude: 52.5105, longitude: 13.4205),
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
        ],
        photos: [
            SessionPhoto(id: "p2-1", uri: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400&h=400&fit=crop", timestamp: "07:30 PM"),
            SessionPhoto(id: "p2-2", uri: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&h=400&fit=crop", timestamp: "09:00 PM"),
            SessionPhoto(id: "p2-3", uri: "https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=400&h=400&fit=crop", timestamp: "10:15 PM"),
            SessionPhoto(id: "p2-4", uri: "https://images.unsplash.com/photo-1571266028243-d220c6a8b0e5?w=400&h=400&fit=crop", timestamp: "11:00 PM"),
        ],
        venueBadges: [
            VenueBadge(id: "vb2-1", name: "Noodle House",       iconType: .restaurant, latitude: 52.5180, longitude: 13.3950, emoji: "🍜"),
            VenueBadge(id: "vb2-2", name: "Rooftop Sunset Bar", iconType: .bar,        latitude: 52.5220, longitude: 13.4080, emoji: "🍹"),
            VenueBadge(id: "vb2-3", name: "Pulse Club",         iconType: .club,       latitude: 52.5105, longitude: 13.4205, emoji: "🎧"),
        ]
    ),

    NightData(
        nightId: "night-2026-04-04",
        title: "Coffee & Chill",
        dateString: "Tuesday, April 4, 2026",
        dateISO: "2026-04-04",
        startTime: "02:00 PM",
        endTime: "05:30 PM",
        totalSteps: 4210,
        totalDuration: "3h 30m",
        totalStopsCount: 2,
        stops: [
            NightStop(stopId: "s3-cafe", stopName: "The Bean Bar",    arrivalTime: "02:15 PM", departureTime: "04:00 PM", iconType: .cafe, latitude: 52.5190, longitude: 13.4010, dwellMinutes: 105),
            NightStop(stopId: "s3-park", stopName: "Mauerpark",       arrivalTime: "04:15 PM", departureTime: "05:15 PM", iconType: .park, latitude: 52.5415, longitude: 13.4020, dwellMinutes: 60),
            NightStop(stopId: "s3-home", stopName: "Home Sweet Home", arrivalTime: "05:30 PM", departureTime: "05:30 PM", iconType: .home, latitude: 52.5260, longitude: 13.4180, dwellMinutes: 0),
        ],
        routeCoordinates: [
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
            RoutePoint(latitude: 52.5220, longitude: 13.4090),
            RoutePoint(latitude: 52.5190, longitude: 13.4010),
            RoutePoint(latitude: 52.5300, longitude: 13.4015),
            RoutePoint(latitude: 52.5415, longitude: 13.4020),
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
        ],
        photos: [
            SessionPhoto(id: "p3-1", uri: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=400&fit=crop", timestamp: "02:30 PM"),
            SessionPhoto(id: "p3-2", uri: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400&h=400&fit=crop", timestamp: "03:15 PM"),
            SessionPhoto(id: "p3-3", uri: "https://images.unsplash.com/photo-1546171753-97d7676e4602?w=400&h=400&fit=crop", timestamp: "04:45 PM"),
        ],
        venueBadges: [
            VenueBadge(id: "vb3-1", name: "The Bean Bar", iconType: .cafe, latitude: 52.5190, longitude: 13.4010, emoji: "☕"),
            VenueBadge(id: "vb3-2", name: "Mauerpark",    iconType: .park, latitude: 52.5415, longitude: 13.4020, emoji: "🌳"),
        ]
    ),

    NightData(
        nightId: "night-2026-03-29",
        title: "Sunset Tapas Night",
        dateString: "Sunday, March 29, 2026",
        dateISO: "2026-03-29",
        startTime: "07:00 PM",
        endTime: "11:15 PM",
        totalSteps: 5480,
        totalDuration: "4h 15m",
        totalStopsCount: 2,
        stops: [
            NightStop(stopId: "s5-rest", stopName: "Casa Tapas",      arrivalTime: "07:30 PM", departureTime: "09:15 PM", iconType: .restaurant, latitude: 52.5165, longitude: 13.3920, dwellMinutes: 105),
            NightStop(stopId: "s5-bar",  stopName: "Terrace Lounge",  arrivalTime: "09:30 PM", departureTime: "10:55 PM", iconType: .bar,        latitude: 52.5245, longitude: 13.4105, dwellMinutes: 85),
            NightStop(stopId: "s5-home", stopName: "Home Sweet Home", arrivalTime: "11:15 PM", departureTime: "11:15 PM", iconType: .home,       latitude: 52.5260, longitude: 13.4180, dwellMinutes: 0),
        ],
        routeCoordinates: [
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
            RoutePoint(latitude: 52.5200, longitude: 13.4000),
            RoutePoint(latitude: 52.5165, longitude: 13.3920),
            RoutePoint(latitude: 52.5205, longitude: 13.4050),
            RoutePoint(latitude: 52.5245, longitude: 13.4105),
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
        ],
        photos: [
            SessionPhoto(id: "p5-1", uri: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=400&fit=crop", timestamp: "07:45 PM"),
            SessionPhoto(id: "p5-2", uri: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400&h=400&fit=crop", timestamp: "09:45 PM"),
            SessionPhoto(id: "p5-3", uri: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400&h=400&fit=crop", timestamp: "10:30 PM"),
        ],
        venueBadges: [
            VenueBadge(id: "vb5-1", name: "Casa Tapas",     iconType: .restaurant, latitude: 52.5165, longitude: 13.3920, emoji: "🍽️"),
            VenueBadge(id: "vb5-2", name: "Terrace Lounge", iconType: .bar,        latitude: 52.5245, longitude: 13.4105, emoji: "🍹"),
        ]
    ),

    NightData(
        nightId: "night-2026-03-22",
        title: "Spring Picnic Day",
        dateString: "Sunday, March 22, 2026",
        dateISO: "2026-03-22",
        startTime: "11:00 AM",
        endTime: "04:45 PM",
        totalSteps: 8240,
        totalDuration: "5h 45m",
        totalStopsCount: 3,
        stops: [
            NightStop(stopId: "s6-cafe", stopName: "Bakers Corner",      arrivalTime: "11:15 AM", departureTime: "12:00 PM", iconType: .cafe,  latitude: 52.5185, longitude: 13.4070, dwellMinutes: 45),
            NightStop(stopId: "s6-park", stopName: "Tempelhofer Feld",   arrivalTime: "12:30 PM", departureTime: "03:00 PM", iconType: .park,  latitude: 52.4735, longitude: 13.4025, dwellMinutes: 150),
            NightStop(stopId: "s6-food", stopName: "Sweet Treats Kiosk", arrivalTime: "03:30 PM", departureTime: "04:30 PM", iconType: .food,  latitude: 52.5120, longitude: 13.4150, dwellMinutes: 60),
            NightStop(stopId: "s6-home", stopName: "Home Sweet Home",    arrivalTime: "04:45 PM", departureTime: "04:45 PM", iconType: .home,  latitude: 52.5260, longitude: 13.4180, dwellMinutes: 0),
        ],
        routeCoordinates: [
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
            RoutePoint(latitude: 52.5185, longitude: 13.4070),
            RoutePoint(latitude: 52.5000, longitude: 13.4060),
            RoutePoint(latitude: 52.4735, longitude: 13.4025),
            RoutePoint(latitude: 52.5020, longitude: 13.4140),
            RoutePoint(latitude: 52.5120, longitude: 13.4150),
            RoutePoint(latitude: 52.5260, longitude: 13.4180),
        ],
        photos: [
            SessionPhoto(id: "p6-1", uri: "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=400&h=400&fit=crop", timestamp: "11:30 AM"),
            SessionPhoto(id: "p6-2", uri: "https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=400&h=400&fit=crop", timestamp: "01:45 PM"),
            SessionPhoto(id: "p6-3", uri: "https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=400&h=400&fit=crop", timestamp: "03:45 PM"),
        ],
        venueBadges: [
            VenueBadge(id: "vb6-1", name: "Bakers Corner",    iconType: .cafe, latitude: 52.5185, longitude: 13.4070, emoji: "🥐"),
            VenueBadge(id: "vb6-2", name: "Tempelhofer Feld", iconType: .park, latitude: 52.4735, longitude: 13.4025, emoji: "🌳"),
            VenueBadge(id: "vb6-3", name: "Sweet Treats",     iconType: .food, latitude: 52.5120, longitude: 13.4150, emoji: "🍦"),
        ]
    ),
]
