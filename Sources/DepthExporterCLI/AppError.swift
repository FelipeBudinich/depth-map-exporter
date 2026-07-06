import Foundation

enum AppError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case validation(String)
    case videoIO(String)
    case coreML(String)
    case internalFailure(String)

    var exitCode: Int32 {
        switch self {
        case .invalidArguments:
            return 2
        case .validation:
            return 3
        case .videoIO:
            return 4
        case .coreML:
            return 5
        case .internalFailure:
            return 6
        }
    }

    var description: String {
        switch self {
        case .invalidArguments(let message):
            return message
        case .validation(let message):
            return message
        case .videoIO(let message):
            return message
        case .coreML(let message):
            return message
        case .internalFailure(let message):
            return message
        }
    }
}

extension Error {
    var appMessage: String {
        if let appError = self as? AppError {
            return appError.description
        }
        return String(describing: self)
    }
}
