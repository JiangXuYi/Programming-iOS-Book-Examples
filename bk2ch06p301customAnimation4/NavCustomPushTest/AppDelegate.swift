
import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
    var window : UIWindow?
    var anim : UIViewImplicitlyAnimating?
    var r2end = CGRect.zero
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
        (self.window!.rootViewController as! UINavigationController).delegate = self
        return true
        
    }
}

extension AppDelegate : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return self
        }
        return nil
    }
//    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        return nil
//    }
}

// simple example of interruptibility
// user can grab image as it grows and drag it around
// we just resume when user lets go
extension AppDelegate {
    func drag (_ g : UIPanGestureRecognizer) {
        let v = g.view!
        switch g.state {
        case .began:
            self.anim?.pauseAnimation()
            fallthrough
        case .changed:
            let delta = g.translation(in:v.superview)
            var c = v.center
            c.x += delta.x; c.y += delta.y
            v.center = c
            g.setTranslation(.zero, in: v.superview)
        case .ended:
            let anim = self.anim as! UIViewPropertyAnimator
            anim.addAnimations {
                v.frame = self.r2end
            }
            let factor = 1 - anim.fractionComplete
            anim.continueAnimation(withTimingParameters: nil, durationFactor: factor)
        default:break
        }
    }
}

extension AppDelegate : UIViewControllerAnimatedTransitioning {
    
    func interruptibleAnimator(using ctx: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        
        if self.anim != nil {
            return self.anim!
        }
        
        let vc1 = ctx.viewController(forKey:UITransitionContextFromViewControllerKey)!
        let vc2 = ctx.viewController(forKey:UITransitionContextToViewControllerKey)!
        let con = ctx.containerView
        let r2end = ctx.finalFrame(for:vc2)
        let v2 = ctx.view(forKey:UITransitionContextToViewKey)!
        
        
        let mvc = vc1 as! MasterViewController
        let tv = mvc.tableView!
        let r = tv.rectForRow(at: IndexPath(row: 0, section: 0))
        let r2 = con.convert(r, from: tv)
        
        v2.frame = r2end
        
        con.addSubview(v2)
        
        let cm = mvc.model[mvc.lastSelection.row]
        let snapshot = UIImageView(image:UIImage(named:cm.name))
        snapshot.contentMode = .scaleAspectFill
        snapshot.clipsToBounds = true
        
        snapshot.frame = r2
        
        con.addSubview(snapshot)
        
        v2.alpha = 0
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(drag))
        snapshot.addGestureRecognizer(pan)
        snapshot.isUserInteractionEnabled = true
        
        let anim = UIViewPropertyAnimator(duration: 2, curve: .linear) {
            snapshot.frame = r2end // I'm sort of cheating; I know it will fill its superview
        }
        
        anim.addCompletion { _ in
            ctx.completeTransition(true)
            v2.alpha = 1
            snapshot.removeFromSuperview()
        }
        
        self.anim = anim
        print("creating animator")
        // also conserve r2end so that we can be interrupted and resumed
        self.r2end = r2end
        
        return anim
    }
    
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval{
        return 2
    }
    
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let anim = self.interruptibleAnimator(using: ctx)
        anim.startAnimation()
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        print("animation ended")
        self.anim = nil
    }

}
