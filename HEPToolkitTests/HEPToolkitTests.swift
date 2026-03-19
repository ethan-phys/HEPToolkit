//
//  HEPToolkitTests.swift
//  HEPToolkitTests
//
//  Created by 邱渔骋 on 27/2/2026.
//

import Testing
@testable import HEPToolkit

struct HEPToolkitTests {

    @Test func prlWordCountExcludesAbstractAndReferences() async throws {
        let tex = #"""
        \begin{abstract}
        Hidden abstract words should not count.
        \end{abstract}
        Visible body text here.
        \caption{caption words}
        \begin{equation}
        E = mc^2
        \end{equation}
        \bibliography{refs}
        """#

        let result = prlWordCount(from: tex)

        #expect(result.textWords >= 4)
        #expect(result.captionWords == 2)
        #expect(result.eqWords == 12)
        #expect(result.total == result.textWords + result.captionWords + result.eqWords)
    }

}
