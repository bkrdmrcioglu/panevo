import Foundation

extension Date {
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var timeAgoDisplay: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: self, to: Date())

        if let year = components.year, year > 0 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        }

        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        }

        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        }

        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }

        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }

        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }

        return "Just now"
    }

    func formatted(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    func isWithin(days: Int, from date: Date = Date()) -> Bool {
        let timeInterval = abs(self.timeIntervalSince(date))
        return timeInterval <= Double(days * 24 * 60 * 60)
    }

    func addDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func addHours(_ hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func addMinutes(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
}

extension TimeInterval {
    var formattedTime: String {
        let seconds = Int(self) % 60
        let minutes = (Int(self) / 60) % 60
        let hours = Int(self) / 3600

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedDuration: String {
        if self < 60 {
            return String(format: "%.0fs", self)
        } else if self < 3600 {
            return String(format: "%.1fm", self / 60)
        } else {
            return String(format: "%.1fh", self / 3600)
        }
    }
}
