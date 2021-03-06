//
//  AKSettings.swift
//  AudioKit
//
//  Created by Stéphane Peter, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//
import Foundation
import AVFoundation

/// Global settings for AudioKit
@objc open class AKSettings: NSObject {

    /// Enum of available buffer lengths
    /// from Shortest: 2 power 5 samples (32 samples = 0.7 ms @ 44100 kz)
    /// to Longest: 2 power 12 samples (4096 samples = 92.9 ms @ 44100 Hz)
    @objc public enum BufferLength: Int {

        /// Shortest
        case shortest = 5

        /// Very Short
        case veryShort = 6

        /// Short
        case short = 7

        /// Medium
        case medium = 8

        /// Long
        case long = 9

        /// Very Long
        case veryLong = 10

        /// Huge
        case huge = 11

        /// Longest
        case longest = 12

        /// The buffer Length expressed as number of samples
        public var samplesCount: AVAudioFrameCount {
            return AVAudioFrameCount(pow(2.0, Double(rawValue)))
        }

        /// The buffer Length expressed as a duration in seconds
        public var duration: Double {
            return Double(samplesCount) / AKSettings.sampleRate
        }
    }

    /// Constants for ramps used in AKParameterRamp.hpp, AKBooster, and others
    @objc public enum RampType: Int {
        case linear = 0
        case exponential = 1
        case logarithmic = 2
        case sCurve = 3
    }

    /// The sample rate in Hertz
    @objc public static var sampleRate: Double = 44_100 {
        didSet {
            #if !os(macOS)
            do {
                try AVAudioSession.sharedInstance().setPreferredSampleRate(sampleRate)
            } catch {
                print(error)
            }
            #else
            //nothing for macOS
            #endif
        }
    }

    /// Number of audio channels: 2 for stereo, 1 for mono
    @objc public static var channelCount: UInt32 = 2

    /// Whether we should be listening to audio input (microphone)
    @objc public static var audioInputEnabled: Bool = false

    /// Whether to allow audio playback to override the mute setting
    @objc public static var playbackWhileMuted: Bool = false

    /// Global audio format AudioKit will default to
    @objc public static var audioFormat: AVAudioFormat {
        return AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)!
    }

    /// Whether to output to the speaker (rather than receiver) when audio input is enabled
    @objc public static var defaultToSpeaker: Bool = false

    /// Whether to use bluetooth when audio input is enabled
    @objc public static var useBluetooth: Bool = false

    #if !os(macOS)
    /// Additional control over the options to use for bluetooth
    @objc public static var bluetoothOptions: AVAudioSession.CategoryOptions = []
    #endif

    /// Whether AirPlay is enabled when audio input is enabled
    @objc public static var allowAirPlay: Bool = false

    /// Global default rampDuration value
    @objc public static var rampDuration: Double = 0.000_2

    /// Allows AudioKit to send Notifications
    @objc public static var notificationsEnabled: Bool = false

    /// AudioKit buffer length is set using AKSettings.BufferLength
    /// default is .VeryLong for a buffer set to 2 power 10 = 1024 samples (232 ms)
    @objc public static var bufferLength: BufferLength = .veryLong

    #if os(macOS)
    /// The hardware ioBufferDuration. Setting this will request the new value, getting
    /// will query the hardware.
    @objc public static var ioBufferDuration: Double {
        set {
            let node = AudioKit.engine.outputNode
            guard let audioUnit = node.audioUnit else { return }
            let samplerate = node.outputFormat(forBus: 0).sampleRate
            var frames = UInt32(round(newValue * samplerate))

            let status = AudioUnitSetProperty(audioUnit,
                                              kAudioDevicePropertyBufferFrameSize,
                                              kAudioUnitScope_Global,
                                              0,
                                              &frames,
                                              UInt32(MemoryLayout<UInt32>.size))
            if status != 0 {
                AKLog("error in set ioBufferDuration status \(status)")
            }
        }
        get {
            let node = AudioKit.engine.outputNode
            guard let audioUnit = node.audioUnit else { return 0 }
            let sampleRate = node.outputFormat(forBus: 0).sampleRate
            var frames = UInt32()
            var propSize = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioUnitGetProperty(audioUnit,
                                              kAudioDevicePropertyBufferFrameSize,
                                              kAudioUnitScope_Global,
                                              0,
                                              &frames,
                                              &propSize)
            if status != 0 {
                AKLog("error in get ioBufferDuration status \(status)")
            }
            return Double(frames) / sampleRate
        }
    }
    #else

    /// The hardware ioBufferDuration. Setting this will request the new value, getting
    /// will query the hardware.
    @objc public static var ioBufferDuration: Double {
        set {
            do {
                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)

            } catch {
                AKLog(error)
            }
        }
        get {
            return AVAudioSession.sharedInstance().ioBufferDuration
        }
    }
    #endif

    /// AudioKit recording buffer length is set using AKSettings.BufferLength
    /// default is .VeryLong for a buffer set to 2 power 10 = 1024 samples (232 ms)
    /// in Apple's doc : "The requested size of the incoming buffers. The implementation may choose another size."
    /// So setting this value may have no effect (depending on the hardware device ?)
    @objc public static var recordingBufferLength: BufferLength = .veryLong

    /// If set to true, Recording will stop after some delay to compensate
    /// latency between time recording is stopped and time it is written to file
    /// If set to false (the default value) , stopping record will be immediate,
    /// even if the last audio frames haven't been recorded to file yet.
    @objc public static var fixTruncatedRecordings = false

    /// Enable AudioKit AVAudioSession Category Management
    @objc public static var disableAVAudioSessionCategoryManagement: Bool = false

    /// If set to true, AudioKit will not deactivate the AVAudioSession when stopping
    @objc public static var disableAudioSessionDeactivationOnStop: Bool = false
    
    /// If set to false, AudioKit will not handle the AVAudioSession route change
    /// notification (AVAudioSessionRouteChange) and will not restart the AVAudioEngine
    /// instance when such notifications are posted. The developer can instead subscribe
    /// to these notifications and restart AudioKit after rebuiling their audio chain.
    @objc public static var enableRouteChangeHandling: Bool = true

    /// If set to false, AudioKit will not handle the AVAudioSession category change
    /// notification (AVAudioEngineConfigurationChange) and will not restart the AVAudioEngine
    /// instance when such notifications are posted. The developer can instead subscribe
    /// to these notifications and restart AudioKit after rebuiling their audio chain.
    @objc public static var enableCategoryChangeHandling: Bool = true

    /// Turn off AudioKit logging
    @objc public static var enableLogging: Bool = true

    #if !os(macOS)
    /// Checks the application's info.plist to see if UIBackgroundModes includes "audio".
    /// If background audio is supported then the system will allow the AVAudioEngine to start even if the app is in,
    /// or entering, a background state. This can help prevent a potential crash
    /// (AVAudioSessionErrorCodeCannotStartPlaying aka error code 561015905) when a route/category change causes
    /// AudioEngine to attempt to start while the app is not active and background audio is not supported.
    @objc public static let appSupportsBackgroundAudio = (Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String])?.contains("audio") ?? false
    #endif
}

#if !os(macOS)
extension AKSettings {

    /// Shortcut for AVAudioSession.sharedInstance()
    @objc public static let session = AVAudioSession.sharedInstance()

    /// Convenience method accessible from Objective-C
    @objc public static func setSession(category: SessionCategory, options: UInt) throws {
        try setSession(category: category, with: AVAudioSession.CategoryOptions(rawValue: options))
    }

    /// Set the audio session type
    @objc public static func setSession(category: SessionCategory,
                                        with options: AVAudioSession.CategoryOptions = []) throws {

        if ❗️AKSettings.disableAVAudioSessionCategoryManagement {
            do {
                try AKTry {
                    try session.setCategory(category.avCategory, mode: .default, options: options)
                }
            } catch let error as NSError {
                AKLog("Error: \(error) Cannot set AVAudioSession Category to \(category) with options: \(options)")
                throw error
            }
        }

        // Preferred IO Buffer Duration
        do {
            try AKTry {
                try session.setPreferredIOBufferDuration(bufferLength.duration)
            }
        } catch let error as NSError {
            AKLog("AKSettings Error: Cannot set Preferred IOBufferDuration to " +
                "\(bufferLength.duration) ( = \(bufferLength.samplesCount) samples)")
            AKLog("AKSettings Error: \(error))")
            throw error
        }

        // Activate session
        do {
            try AKTry {
                try session.setActive(true)
            }
        } catch let error as NSError {
            AKLog("AKSettings Error: Cannot set AVAudioSession.setActive to true", error)
            throw error
        }
    }

    @objc public static func computedSessionCategory() -> SessionCategory {
        if AKSettings.audioInputEnabled {
            return .playAndRecord
        } else if AKSettings.playbackWhileMuted {
            return .playback
        } else {
            return .ambient
        }
    }

    @objc public static func computedSessionOptions() -> AVAudioSession.CategoryOptions {

        var options: AVAudioSession.CategoryOptions = [.mixWithOthers]

        if AKSettings.audioInputEnabled {

            options = options.union(.mixWithOthers)

            #if !os(tvOS)
            if #available(iOS 10.0, *) {
                // Blueooth Options
                // .allowBluetooth can only be set with the categories .playAndRecord and .record
                // .allowBluetoothA2DP comes for free if the category is .ambient, .soloAmbient, or
                // .playback. This option is cleared if the category is .record, or .multiRoute. If this
                // option and .allowBluetooth are set and a device supports Hands-Free Profile (HFP) and the
                // Advanced Audio Distribution Profile (A2DP), the Hands-Free ports will be given a higher
                // priority for routing.
                if !AKSettings.bluetoothOptions.isEmpty {
                    options = options.union(AKSettings.bluetoothOptions)
                } else if AKSettings.useBluetooth {
                    // If bluetoothOptions aren't specified
                    // but useBluetooth is then we will use these defaults
                    options = options.union([.allowBluetooth,
                                             .allowBluetoothA2DP])
                }

                // AirPlay
                if AKSettings.allowAirPlay {
                    options = options.union(.allowAirPlay)
                }
            } else if !AKSettings.bluetoothOptions.isEmpty ||
                AKSettings.useBluetooth ||
                AKSettings.allowAirPlay {
                AKLog("Some of the specified AKSettings are not supported by iOS 9 and were ignored.")
            }

            // Default to Speaker
            if AKSettings.defaultToSpeaker {
                options = options.union(.defaultToSpeaker)
            }
            #endif
        }

        return options
    }

    /// Checks if headphones are connected
    /// Returns true if headPhones are connected, otherwise return false
    @objc public static var headPhonesPlugged: Bool {
        let headphonePortTypes: [AVAudioSession.Port] =
                    [.headphones, .bluetoothHFP, .bluetoothA2DP]
        return session.currentRoute.outputs.contains {
            return headphonePortTypes.contains($0.portType)
        }
    }

    /// Enum of available AVAudioSession Categories
    @objc public enum SessionCategory: Int, CustomStringConvertible {
        /// Audio silenced by silent switch and screen lock - audio is mixable
        case ambient
        /// Audio is silenced by silent switch and screen lock - audio is non mixable
        case soloAmbient
        /// Audio is not silenced by silent switch and screen lock - audio is non mixable
        case playback
        /// Silences playback audio
        case record
        /// Audio is not silenced by silent switch and screen lock - audio is non mixable.
        /// To allow mixing see AVAudioSessionCategoryOptionMixWithOthers.
        case playAndRecord
        #if !os(tvOS)
        /// Disables playback and recording; deprecated in iOS 10, unavailable on tvOS
        case audioProcessing
        #endif
        /// Use to multi-route audio. May be used on input, output, or both.
        case multiRoute

        public var description: String {
            switch self {
            case .ambient:
                return AVAudioSession.Category.ambient.rawValue
            case .soloAmbient:
                return AVAudioSession.Category.soloAmbient.rawValue
            case .playback:
                return AVAudioSession.Category.playback.rawValue
            case .record:
                return AVAudioSession.Category.record.rawValue
            case .playAndRecord:
                return AVAudioSession.Category.playAndRecord.rawValue
            case .multiRoute:
                return AVAudioSession.Category.multiRoute.rawValue
            default :
                return AVAudioSession.Category.soloAmbient.rawValue
            }
        }
        
        public var avCategory: AVAudioSession.Category {
            switch self {
            case .ambient:
                return .ambient
            case .soloAmbient:
                return .soloAmbient
            case .playback:
                return .playback
            case .record:
                return .record
            case .playAndRecord:
                return .playAndRecord
            case .multiRoute:
                return .multiRoute
            default:
                return .soloAmbient
            }
        }
    }
}

#endif
